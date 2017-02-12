require 'rspec/expectations'
include RSpec::Matchers

RSpec::Matchers.define :look_like do |expected|
  match do |actual|
    actual.to_s == expected
  end
end

module Atom
  def inspect
    "«#{to_s}»"
  end
end

class Variable
  include Atom

  def initialize(name)
    @name = name
  end

  attr_reader :name

  def to_s
    name
  end
end

def scope(&block)
  names = block.parameters.map { |type, name| name }
  variables = names.map(&Variable.method(:new))
  block.call(*variables)
end

class Formula < Struct.new(:parts)
  include Atom

  def to_s
    parts.map(&:to_s).join(' ')
  end
end

def form(*args)
  Formula.new(args)
end

scope do |t₂, t₃|
  if_true = form(form(:if, :true, :then, t₂, :else, t₃), :→, t₂)
  if_false = form(form(:if, :false, :then, t₂, :else, t₃), :→, t₃)

  expect(if_true).to look_like 'if true then t₂ else t₃ → t₂'
  expect(if_false).to look_like 'if false then t₂ else t₃ → t₃'
end

scope do |t₁, t₂, t₃, t₁′|
  premise = form(t₁, :→, t₁′)
  conclusion = form(form(:if, t₁, :then, t₂, :else, t₃), :→, form(:if, t₁′, :then, t₂, :else, t₃))

  expect(premise).to look_like 't₁ → t₁′'
  expect(conclusion).to look_like 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃'
end

class State
  def initialize(values = {})
    @values = values
  end

  attr_reader :values

  def assign_values(more_values)
    self.class.new(values.merge(more_values) { |key| raise key })
  end

  def value_of(key)
    if values.has_key?(key)
      value_of values.fetch(key)
    elsif key.is_a?(Formula)
      Formula.new(key.parts.map(&method(:value_of)))
    else
      key
    end
  end

  def unify(a, b)
    a, b = value_of(a), value_of(b)

    if a == b
      self
    elsif a.is_a?(Variable)
      assign_values a => b
    elsif b.is_a?(Variable)
      assign_values b => a
    elsif a.is_a?(Formula) && b.is_a?(Formula)
      if a.parts.length == b.parts.length
        [a, b].map(&:parts).transpose.inject(self) do |state, (a, b)|
          state && state.unify(a, b)
        end
      end
    end
  end
end

scope do |t₁|
  state = State.new.unify(t₁, :true)
  expect(state.value_of(t₁)).to eq :true
end

scope do |t₁, t₂|
  state = State.new.unify(t₂, :false).unify(t₂, t₁)
  expect(state.value_of(t₁)).to eq :false
end

scope do |t₂, t₃, result|
  if_true = form(form(:if, :true, :then, t₂, :else, t₃), :→, t₂)
  if_false = form(form(:if, :false, :then, t₂, :else, t₃), :→, t₃)
  formula = form(form(:if, :true, :then, :false, :else, :true), :→, result)

  state = State.new.unify(formula, if_true)
  expect(state.value_of(t₂)).to eq :false
  expect(state.value_of(t₃)).to eq :true
  expect(state.value_of(result)).to eq :false

  state = State.new.unify(formula, if_false)
  expect(state).to be_nil
end

scope do |t₂, t₃, result|
  if_true = form(form(:if, :true, :then, t₂, :else, t₃), :→, t₂)
  if_false = form(form(:if, :false, :then, t₂, :else, t₃), :→, t₃)
  formula = form(form(:if, :false, :then, :false, :else, :true), :→, result)

  state = State.new.unify(formula, if_true)
  expect(state).to be_nil

  state = State.new.unify(formula, if_false)
  expect(state.value_of(t₂)).to eq :false
  expect(state.value_of(t₃)).to eq :true
  expect(state.value_of(result)).to eq :true
end

class Rule
  def initialize(premises, conclusion)
    @premises, @conclusion = premises, conclusion
  end

  attr_reader :premises, :conclusion

  def to_s
    premises_string = premises.map(&:to_s).join('  ')
    conclusion_string = conclusion.to_s

    [
      (premises_string unless premises_string.empty?),
      '-' * [premises_string, conclusion_string].map(&:length).max,
      conclusion_string
    ].compact.join("\n")
  end

  def match(formula, state)
    state.unify(formula, conclusion)
  end

  def matches?(*args)
    !match(*args).nil?
  end
end

rules = [
  scope { |t₂, t₃| Rule.new([], form(form(:if, :true, :then, t₂, :else, t₃), :→, t₂)) },
  scope { |t₂, t₃| Rule.new([], form(form(:if, :false, :then, t₂, :else, t₃), :→, t₃)) },
  scope { |t₁, t₂, t₃, t₁′| Rule.new([form(t₁, :→, t₁′)], form(form(:if, t₁, :then, t₂, :else, t₃), :→, form(:if, t₁′, :then, t₂, :else, t₃))) }
]

def match_rules(rules, formula, state)
  rules.
    select { |rule| rule.matches?(formula, state) }.
    map { |rule| [rule, rule.match(formula, state)] }
end

scope do |result|
  formula = form(form(:if, :false, :then, :false, :else, :true), :→, result)
  state = State.new
  matches = match_rules(rules, formula, state)
  rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if false then' }
  expect(state.value_of(result)).to eq :true
end

scope do |result|
  formula = form(form(:if, form(:if, :true, :then, :true, :else, :false), :then, :false, :else, :true), :→, result)
  state = State.new

  matches = match_rules(rules, formula, state)
  rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if t₁ then' }
  expect(state.value_of(result)).to look_like 'if t₁′ then false else true'

  expect(rule.premises.length).to eq 1
  formula = rule.premises.first

  matches = match_rules(rules, formula, state)
  rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if true then' }
  expect(state.value_of(result)).to look_like 'if true then false else true'

  expect(rule.premises.length).to eq 0
end

def derive(rules, formula, state)
  match_rules(rules, formula, state).flat_map { |rule, state|
    rule.premises.inject([state]) { |states, premise|
      states.flat_map { |state| derive(rules, premise, state) }
    }
  }.compact
end

scope do |result|
  formula = form(form(:if, :false, :then, :false, :else, :true), :→, result)
  states = derive(rules, formula, State.new)
  expect(states.length).to eq 1
  state = states.first
  expect(state.value_of(result)).to eq :true
end

scope do |result|
  formula = form(form(:if, form(:if, :true, :then, :true, :else, :false), :then, :false, :else, :true), :→, result)
  states = derive(rules, formula, State.new)
  expect(states.length).to eq 1
  state = states.first
  expect(state.value_of(result)).to look_like 'if true then false else true'

  formula = form(state.value_of(result), :→, result)
  states = derive(rules, formula, State.new)
  expect(states.length).to eq 1
  state = states.first
  expect(state.value_of(result)).to look_like 'false'
end

NoRuleApplies = Class.new(StandardError)
Nondeterministic = Class.new(StandardError)

def eval1(rules, term)
  scope do |result|
    states = derive(rules, form(term, :→, result), State.new)

    raise NoRuleApplies if states.empty?
    raise Nondeterministic if states.length > 1

    states.first.value_of(result)
  end
end

term = form(:if, :false, :then, :false, :else, :true)
term = eval1(rules, term)
expect(term).to eq :true

term = form(:if, form(:if, :true, :then, :true, :else, :false), :then, :false, :else, :true)
term = eval1(rules, term)
expect(term).to eq form(:if, :true, :then, :false, :else, :true)
term = eval1(rules, term)
expect(term).to eq :false

def eval(rules, term)
  begin
    eval(rules, eval1(rules, term))
  rescue NoRuleApplies
    term
  end
end

expect(eval(rules, form(:if, :false, :then, :false, :else, :true))).to eq :true
expect(eval(rules, form(:if, form(:if, :true, :then, :true, :else, :false), :then, :false, :else, :true))).to eq :false
