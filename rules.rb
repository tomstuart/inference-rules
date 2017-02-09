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

class Formula
  include Atom

  def initialize(parts)
    @parts = parts
  end

  attr_reader :parts

  def to_s
    parts.map(&:to_s).join(' ')
  end
end

t₁, t₂, t₃, t₁′ = %i(t₁ t₂ t₃ t₁′).map(&Variable.method(:new))
if_true = Formula.new([:if, :true, :then, t₂, :else, t₃, :→, t₂])
if_false = Formula.new([:if, :false, :then, t₂, :else, t₃, :→, t₃])

expect(if_true).to look_like 'if true then t₂ else t₃ → t₂'
expect(if_false).to look_like 'if false then t₂ else t₃ → t₃'

premise = Formula.new([t₁, :→, t₁′])
conclusion = Formula.new([:if, t₁, :then, t₂, :else, t₃, :→, :if, t₁′, :then, t₂, :else, t₃])

expect(premise).to look_like 't₁ → t₁′'
expect(conclusion).to look_like 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃'

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

state = State.new.unify(t₁, :true)
expect(state.value_of(t₁)).to eq :true

state = State.new.unify(t₂, :false).unify(t₂, t₁)
expect(state.value_of(t₁)).to eq :false

result = Variable.new(:result)

term = Formula.new([:if, :true, :then, :false, :else, :true, :→, result])
state = State.new.unify(term, if_true)
expect(state.value_of(t₂)).to eq :false
expect(state.value_of(t₃)).to eq :true
expect(state.value_of(result)).to eq :false
state = State.new.unify(term, if_false)
expect(state).to be_nil

term = Formula.new([:if, :false, :then, :false, :else, :true, :→, result])
state = State.new.unify(term, if_true)
expect(state).to be_nil
state = State.new.unify(term, if_false)
expect(state.value_of(t₂)).to eq :false
expect(state.value_of(t₃)).to eq :true
expect(state.value_of(result)).to eq :true
