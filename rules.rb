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

  def build_zero
    :'0'
  end

  def build_succ(term)
    Formula.new([:succ, term])
  end

  def build_pred(term)
    Formula.new([:pred, term])
  end

  def build_iszero(term)
    Formula.new([:iszero, term])
  end

  def build_evaluates(before, after)
    Formula.new([before, :→, after])
  end

  def build_element_of(element, set)
    Formula.new([element, :∈, set])
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
    left = parse_term
    symbol = read %r{→|∈}
    right = parse_term

    case symbol
    when '→'
      builder.build_evaluates(left, right)
    when '∈'
      builder.build_element_of(left, right)
    else
      complain
    end
  end

  def parse_term
    if can_read? %r{if}
      parse_conditional
    elsif can_read? %r{true|false}
      parse_boolean
    elsif can_read? %r{0}
      parse_zero
    elsif can_read? %r{succ|pred|iszero}
      parse_numeric_operation
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

  def parse_zero
    read %r{0}
    builder.build_zero
  end

  def parse_numeric_operation
    numeric_operation = read_numeric_operation
    argument = parse_term

    case numeric_operation
    when 'succ'
      builder.build_succ(argument)
    when 'pred'
      builder.build_pred(argument)
    when 'iszero'
      builder.build_iszero(argument)
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

  def read_numeric_operation
    read %r{succ|pred|iszero}
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

def find_variable(formula, name)
  case formula
  when Variable
    formula if formula.name == name
  when Formula
    formula.parts.each do |part|
      result = find_variable(part, name)
      return result if result
    end
    nil
  end
end

term = parse_term('t₁')
state = State.new.unify(term, parse_term('true'))
expect(state.value_of(find_variable(term, 't₁'))).to look_like 'true'

term₁ = parse_term('t₁')
term₂ = parse_term('t₂')
state = State.new.unify(term₂, parse_term('false')).unify(term₂, term₁)
expect(state.value_of(find_variable(term₁, 't₁'))).to look_like 'false'

if_true = parse_formula('if true then t₂ else t₃ → t₂')
if_false = parse_formula('if false then t₂ else t₃ → t₃')
formula = parse_formula('if true then false else true → result')
state = State.new.unify(formula, if_true)
expect(state.value_of(find_variable(if_true, 't₂'))).to look_like 'false'
expect(state.value_of(find_variable(if_true, 't₃'))).to look_like 'true'
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'false'
state = State.new.unify(formula, if_false)
expect(state).to be_nil

if_true = parse_formula('if true then t₂ else t₃ → t₂')
if_false = parse_formula('if false then t₂ else t₃ → t₃')
formula = parse_formula('if false then false else true → result')
state = State.new.unify(formula, if_true)
expect(state).to be_nil
state = State.new.unify(formula, if_false)
expect(state.value_of(find_variable(if_false, 't₂'))).to look_like 'false'
expect(state.value_of(find_variable(if_false, 't₃'))).to look_like 'true'
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

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
  # -> { parse_rule([], 'true ∈ T') }, # FIXME T not a variable
  # -> { parse_rule([], 'false ∈ T') }, # FIXME T not a variable
  # -> { parse_rule(['t₁ ∈ T', 't₂ ∈ T', 't₃ ∈ T'], 'if t₁ then t₂ else t₃ ∈ T') }, # FIXME T not a variable

  -> { parse_rule([], 'if true then t₂ else t₃ → t₂') },
  -> { parse_rule([], 'if false then t₂ else t₃ → t₃') },
  -> { parse_rule(['t₁ → t₁′'], 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃') }
]

def match_rules(rules, formula, state)
  rules.
    map(&:call).
    select { |rule| rule.matches?(formula, state) }.
    map { |rule| [rule, rule.match(formula, state)] }
end

formula = parse_formula('if false then false else true → result')
state = State.new
matches = match_rules(rules, formula, state)
rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if false then' }
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

formula = parse_formula('if if true then true else false then false else true → result')
state = State.new
matches = match_rules(rules, formula, state)
rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if t₁ then' }
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if t₁′ then false else true'
expect(rule.premises.length).to eq 1
premise = rule.premises.first
matches = match_rules(rules, premise, state)
rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if true then' }
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if true then false else true'
expect(rule.premises.length).to eq 0

def derive(rules, formula, state)
  match_rules(rules, formula, state).flat_map { |rule, state|
    rule.premises.inject([state]) { |states, premise|
      states.flat_map { |state| derive(rules, premise, state) }
    }
  }.compact
end

formula = parse_formula('if false then false else true → result')
states = derive(rules, formula, State.new)
expect(states.length).to eq 1
state = states.first
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

formula = parse_formula('if if true then true else false then false else true → result')
states = derive(rules, formula, State.new)
expect(states.length).to eq 1
state = states.first
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if true then false else true'
formula = Builder.new.build_evaluates(state.value_of(find_variable(formula, 'result')), parse_term('result'))
states = derive(rules, formula, State.new)
expect(states.length).to eq 1
state = states.first
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'false'

formula = parse_formula('if if if true then false else true then true else false then false else true → result')
states = derive(rules, formula, State.new)
expect(states.length).to eq 1
state = states.first
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if if false then true else false then false else true'
formula = Builder.new.build_evaluates(state.value_of(find_variable(formula, 'result')), parse_term('result'))
states = derive(rules, formula, State.new)
expect(states.length).to eq 1
state = states.first
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if false then false else true'
formula = Builder.new.build_evaluates(state.value_of(find_variable(formula, 'result')), parse_term('result'))
states = derive(rules, formula, State.new)
expect(states.length).to eq 1
state = states.first
expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

NoRuleApplies = Class.new(StandardError)
Nondeterministic = Class.new(StandardError)

def eval1(rules, term)
  result = Builder.new.build_variable('result')
  formula = Builder.new.build_evaluates(term, result)
  states = derive(rules, formula, State.new)

  raise NoRuleApplies if states.empty?
  raise Nondeterministic, states.map { |s| s.value_of(result) } if states.length > 1

  states.first.value_of(result)
end

RSpec::Matchers.define :reduce_to do |expected|
  match do |actual|
    eval1(rules, parse_term(actual)) == parse_term(expected)
  end
end

expect('if false then false else true').to reduce_to 'true'

expect('if if true then true else false then false else true').to reduce_to 'if true then false else true'
expect('if true then false else true').to reduce_to 'false'

expect('if if if true then false else true then true else false then false else true').to reduce_to 'if if false then true else false then false else true'
expect('if if false then true else false then false else true').to reduce_to 'if false then false else true'
expect('if false then false else true').to reduce_to 'true'

def eval(rules, term)
  begin
    eval(rules, eval1(rules, term))
  rescue NoRuleApplies
    term
  end
end

RSpec::Matchers.define :evaluate_to do |expected|
  match do |actual|
    @result = eval(rules, parse_term(actual))
    @result == parse_term(expected)
  end

  failure_message do |actual|
    %Q{expected "#{actual}" to evaluate to "#{expected}", but got "#{@result}" instead}
  end
end

expect('if false then false else true').to evaluate_to 'true'
expect('if if true then true else false then false else true').to evaluate_to 'false'
expect('if if if true then false else true then true else false then false else true').to evaluate_to 'true'

rules += [
  # -> { parse_rule([], '0 ∈ T') }, # FIXME T not a variable
  # -> { parse_rule(['t₁ ∈ T'], 'succ t₁ ∈ T') }, # FIXME T not a variable
  # -> { parse_rule(['t₁ ∈ T'], 'pred t₁ ∈ T') }, # FIXME T not a variable
  # -> { parse_rule(['t₁ ∈ T'], 'iszero t₁ ∈ T') }, # FIXME T not a variable

  -> { parse_rule([], '0 ∈ NV') }, # FIXME NV not a variable
  -> { parse_rule(['nv₁ ∈ NV'], 'succ nv₁ ∈ NV') }, # FIXME NV not a variable

  -> { parse_rule(['t₁ → t₁′'], 'succ t₁ → succ t₁′') },
  -> { parse_rule([], 'pred 0 → 0') },
  -> { parse_rule(['nv₁ ∈ NV'], 'pred succ nv₁ → nv₁') }, # FIXME NV not a variable
  -> { parse_rule(['t₁ → t₁′'], 'pred t₁ → pred t₁′') },
  -> { parse_rule([], 'iszero 0 → true') },
  -> { parse_rule(['nv₁ ∈ NV'], 'iszero succ nv₁ → false') }, # FIXME NV not a variable
  -> { parse_rule(['t₁ → t₁′'], 'iszero t₁ → iszero t₁′') }
]

expect('pred succ succ 0').to evaluate_to 'succ 0'
expect('if iszero succ 0 then succ pred 0 else pred succ 0').to evaluate_to '0'
expect('pred succ succ pred 0').to evaluate_to 'succ 0'
expect('pred succ succ true').to evaluate_to 'pred succ succ true'
expect('iszero 0').to evaluate_to 'true'
expect('iszero succ 0').to evaluate_to 'false'
expect('iszero succ succ succ succ 0').to evaluate_to 'false'
expect('iszero succ true').to evaluate_to 'iszero succ true'
