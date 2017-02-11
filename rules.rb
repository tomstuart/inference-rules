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
  term = form(form(:if, :true, :then, :false, :else, :true), :→, result)

  state = State.new.unify(term, if_true)
  expect(state.value_of(t₂)).to eq :false
  expect(state.value_of(t₃)).to eq :true
  expect(state.value_of(result)).to eq :false

  state = State.new.unify(term, if_false)
  expect(state).to be_nil
end

scope do |t₂, t₃, result|
  if_true = form(form(:if, :true, :then, t₂, :else, t₃), :→, t₂)
  if_false = form(form(:if, :false, :then, t₂, :else, t₃), :→, t₃)
  term = form(form(:if, :false, :then, :false, :else, :true), :→, result)

  state = State.new.unify(term, if_true)
  expect(state).to be_nil

  state = State.new.unify(term, if_false)
  expect(state.value_of(t₂)).to eq :false
  expect(state.value_of(t₃)).to eq :true
  expect(state.value_of(result)).to eq :true
end

class Rule
  def initialize(premises, conclusion)
    @premises, @conclusion = premises, conclusion
  end

  attr_reader :premises, :conclusion
end

scope do |t₁, t₂, t₃, t₁′|
  if_true = form(form(:if, :true, :then, t₂, :else, t₃), :→, t₂)
  if_false = form(form(:if, :false, :then, t₂, :else, t₃), :→, t₃)
  premise = form(t₁, :→, t₁′)
  conclusion = form(form(:if, t₁, :then, t₂, :else, t₃), :→, form(:if, t₁′, :then, t₂, :else, t₃))

  rules = [
    Rule.new([], if_true),
    Rule.new([], if_false),
    Rule.new([premise], conclusion)
  ]

  scope do |result|
    term = form(form(:if, :false, :then, :false, :else, :true), :→, result)
    state = State.new
    rule = rules.detect { |r| state.unify(term, r.conclusion) != nil }
    expect(rule).to eq rules[1]
    state = state.unify(term, rule.conclusion)
    expect(state.value_of(result)).to eq :true
  end

  scope do |result|
    term = form(form(:if, form(:if, :true, :then, :false, :else, :true), :then, :false, :else, :true), :→, result)
    state = State.new

    rule = rules.detect { |r| state.unify(term, r.conclusion) != nil }
    expect(rule).to eq rules[2]
    state = state.unify(term, rule.conclusion)
    expect(state.value_of(result)).to eq form(:if, t₁′, :then, :false, :else, :true)

    expect(rule.premises.length).to eq 1
    term = rule.premises.first

    rule = rules.detect { |r| state.unify(term, r.conclusion) != nil }
    expect(rule).to eq rules[0]
    state = state.unify(term, rule.conclusion)
    expect(state.value_of(result)).to eq form(:if, :false, :then, :false, :else, :true)

    expect(rule.premises.length).to eq 0
  end
end
