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
  builder = Builder.new
  names = block.parameters.map { |type, name| name }
  variables = names.map(&builder.method(:build_variable))
  block.call(*variables)
end

class Formula < Struct.new(:parts)
  include Atom

  def to_s
    parts.map(&:to_s).join(' ')
  end
end

class Builder
  def initialize
    self.variables = Hash.new { |vars, name| vars[name] = Variable.new(name) }
  end

  def build_true
    :true
  end

  def build_false
    :false
  end

  def build_conditional(condition, consequent, alternative)
    Formula.new([:if, condition, :then, consequent, :else, alternative])
  end

  def build_evaluates(before, after)
    Formula.new([before, :→, after])
  end

  def build_variable(name)
    variables[name]
  end

  private

  attr_accessor :variables
end

class Parser
  def initialize(builder)
    @builder = builder
  end

  def parse_complete_formula(string)
    self.string = string
    parse_everything { parse_formula }
  end

  def parse_complete_term(string)
    self.string = string
    parse_everything { parse_term }
  end

  private

  attr_reader :builder, :string

  def string=(string)
    @string = string.strip
  end

  def parse_everything
    result = yield
    complain unless string.empty?
    result
  end

  def parse_formula
    before = parse_term
    read %r{→}
    after = parse_term

    builder.build_evaluates(before, after)
  end

  def parse_term
    if can_read? %r{if}
      parse_conditional
    elsif can_read? %r{true|false}
      parse_boolean
    elsif can_read? %r{[\p{L}\p{N}]+\p{Po}*}
      parse_variable
    else
      complain
    end
  end

  def parse_conditional
    read %r{if}
    condition = parse_term
    read %r{then}
    consequent = parse_term
    read %r{else}
    alternative = parse_term

    builder.build_conditional(condition, consequent, alternative)
  end

  def parse_boolean
    case read_boolean
    when 'true'
      builder.build_true
    when 'false'
      builder.build_false
    else
      complain
    end
  end

  def parse_variable
    builder.build_variable(read_name)
  end

  def read_boolean
    read %r{true|false}
  end

  def read_name
    read %r{[\p{L}\p{N}]+\p{Po}*}
  end

  def can_read?(pattern)
    !try_match(pattern).nil?
  end

  def read(pattern)
    match = try_match(pattern) || complain(pattern)
    self.string = match.post_match
    match.to_s
  end

  def try_match(pattern)
    /\A#{pattern}/.match(string)
  end

  def complain(expected = nil)
    complaint = "unexpected #{string.slice(0)}"
    complaint << ", expected #{expected.inspect}" if expected

    raise complaint
  end
end

def parse_term(string)
  Parser.new(Builder.new).parse_complete_term(string)
end

def parse_formula(string)
  Parser.new(Builder.new).parse_complete_formula(string)
end

def parse_rule(premise_strings, conclusion_string)
  builder = Builder.new
  premises = premise_strings.map { |string| Parser.new(builder).parse_complete_formula(string) }
  conclusion = Parser.new(builder).parse_complete_formula(conclusion_string)

  Rule.new(premises, conclusion)
end

def yes(*args)
  Builder.new.build_true(*args)
end

def no(*args)
  Builder.new.build_false(*args)
end

def conditional(*args)
  Builder.new.build_conditional(*args)
end

def evaluates(*args)
  Builder.new.build_evaluates(*args)
end

expect(parse_term('true')).to eq yes
expect(parse_term('if false then false else true')).to eq conditional(no, no, yes)
expect(parse_term('if if true then true else false then false else true')).to eq conditional(conditional(yes, yes, no), no, yes)

expect(parse_formula('if true then t₂ else t₃ → t₂')).to look_like 'if true then t₂ else t₃ → t₂'
expect(parse_formula('if false then t₂ else t₃ → t₃')).to look_like 'if false then t₂ else t₃ → t₃'

expect(parse_formula('t₁ → t₁′')).to look_like 't₁ → t₁′'
expect(parse_formula('if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃')).to look_like 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃'

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
  state = State.new.unify(t₁, yes)
  expect(state.value_of(t₁)).to eq yes
end

scope do |t₁, t₂|
  state = State.new.unify(t₂, no).unify(t₂, t₁)
  expect(state.value_of(t₁)).to eq no
end

scope do |t₂, t₃, result|
  if_true = evaluates(conditional(yes, t₂, t₃), t₂)
  if_false = evaluates(conditional(no, t₂, t₃), t₃)
  formula = evaluates(parse_term('if true then false else true'), result)

  state = State.new.unify(formula, if_true)
  expect(state.value_of(t₂)).to eq no
  expect(state.value_of(t₃)).to eq yes
  expect(state.value_of(result)).to eq no

  state = State.new.unify(formula, if_false)
  expect(state).to be_nil
end

scope do |t₂, t₃, result|
  if_true = evaluates(conditional(yes, t₂, t₃), t₂)
  if_false = evaluates(conditional(no, t₂, t₃), t₃)
  formula = evaluates(parse_term('if false then false else true'), result)

  state = State.new.unify(formula, if_true)
  expect(state).to be_nil

  state = State.new.unify(formula, if_false)
  expect(state.value_of(t₂)).to eq no
  expect(state.value_of(t₃)).to eq yes
  expect(state.value_of(result)).to eq yes
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
  parse_rule([], 'if true then t₂ else t₃ → t₂'),
  parse_rule([], 'if false then t₂ else t₃ → t₃'),
  parse_rule(['t₁ → t₁′'], 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃')
]

def match_rules(rules, formula, state)
  rules.
    select { |rule| rule.matches?(formula, state) }.
    map { |rule| [rule, rule.match(formula, state)] }
end

scope do |result|
  formula = evaluates(parse_term('if false then false else true'), result)
  state = State.new
  matches = match_rules(rules, formula, state)
  rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if false then' }
  expect(state.value_of(result)).to eq yes
end

scope do |result|
  formula = evaluates(parse_term('if if true then true else false then false else true'), result)
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
  formula = evaluates(parse_term('if false then false else true'), result)
  states = derive(rules, formula, State.new)
  expect(states.length).to eq 1
  state = states.first
  expect(state.value_of(result)).to eq yes
end

scope do |result|
  formula = evaluates(parse_term('if if true then true else false then false else true'), result)
  states = derive(rules, formula, State.new)
  expect(states.length).to eq 1
  state = states.first
  expect(state.value_of(result)).to look_like 'if true then false else true'

  formula = evaluates(state.value_of(result), result)
  states = derive(rules, formula, State.new)
  expect(states.length).to eq 1
  state = states.first
  expect(state.value_of(result)).to look_like 'false'
end

NoRuleApplies = Class.new(StandardError)
Nondeterministic = Class.new(StandardError)

def eval1(rules, term)
  scope do |result|
    states = derive(rules, evaluates(term, result), State.new)

    raise NoRuleApplies if states.empty?
    raise Nondeterministic if states.length > 1

    states.first.value_of(result)
  end
end

RSpec::Matchers.define :reduce_to do |expected|
  match do |actual|
    eval1(rules, parse_term(actual)) == parse_term(expected)
  end
end

expect('if false then false else true').to reduce_to 'true'

expect('if if true then true else false then false else true').to reduce_to 'if true then false else true'
expect('if true then false else true').to reduce_to 'false'

def eval(rules, term)
  begin
    eval(rules, eval1(rules, term))
  rescue NoRuleApplies
    term
  end
end

RSpec::Matchers.define :evaluate_to do |expected|
  match do |actual|
    eval(rules, parse_term(actual)) == parse_term(expected)
  end
end

expect('if false then false else true').to evaluate_to 'true'
expect('if if true then true else false then false else true').to evaluate_to 'false'
