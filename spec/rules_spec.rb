require 'state'

require 'support/builder_helpers'
require 'support/parser_helpers'
require 'support/pretty_printing_matchers'
require 'support/rule_helpers'

RSpec.describe do
  include BuilderHelpers
  include ParserHelpers
  include PrettyPrintingMatchers
  include RuleHelpers

  specify do
    def evaluates(before, after)
      sequence(before, word('→'), after)
    end

    term = parse('_t₁')
    state = State.new.unify(term, parse('true'))
    expect(state.value_of(term.find_variable('t₁'))).to look_like 'true'

    term₁ = parse('_t₁')
    term₂ = parse('_t₂')
    state = State.new.unify(term₂, parse('false')).unify(term₂, term₁)
    expect(state.value_of(term₁.find_variable('t₁'))).to look_like 'false'

    if_true = parse('(if true then _t₂ else _t₃) → _t₂')
    if_false = parse('(if false then _t₂ else _t₃) → _t₃')
    formula = parse('(if true then false else true) → _result')
    state = State.new.unify(formula, if_true)
    expect(state.value_of(if_true.find_variable('t₂'))).to look_like 'false'
    expect(state.value_of(if_true.find_variable('t₃'))).to look_like 'true'
    expect(state.value_of(formula.find_variable('result'))).to look_like 'false'
    state = State.new.unify(formula, if_false)
    expect(state).to be_nil

    if_true = parse('(if true then _t₂ else _t₃) → _t₂')
    if_false = parse('(if false then _t₂ else _t₃) → _t₃')
    formula = parse('(if false then false else true) → _result')
    state = State.new.unify(formula, if_true)
    expect(state).to be_nil
    state = State.new.unify(formula, if_false)
    expect(state.value_of(if_false.find_variable('t₂'))).to look_like 'false'
    expect(state.value_of(if_false.find_variable('t₃'))).to look_like 'true'
    expect(state.value_of(formula.find_variable('result'))).to look_like 'true'

    rules = [
      rule([], 'true ∈ T'),
      rule([], 'false ∈ T'),
      rule(['_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T'], '(if _t₁ then _t₂ else _t₃) ∈ T'),

      rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if true then _t₂ else _t₃) → _t₂'),
      rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if false then _t₂ else _t₃) → _t₃'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T', '_t₁′ ∈ T'], '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)')
    ]

    def match_rules(rules, expression, state)
      rules.
        map { |rule| rule.call(Builder.new) }.
        select { |rule| rule.matches?(expression, state) }.
        map { |rule| rule.match(expression, state) }
    end

    formula = parse('(if false then false else true) → _result')
    state = State.new
    matches = match_rules(rules, formula, state)
    expect(matches.length).to eq 2
    state, premises = matches.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'true'

    formula = parse('(if (if true then true else false) then false else true) → _result')
    state = State.new
    matches = match_rules(rules, formula, state)
    expect(matches.length).to eq 1
    state, premises = matches.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'if _t₁′ then false else true'
    expect(premises.length).to eq 5
    premise = premises.first
    matches = match_rules(rules, premise, state)
    expect(matches.length).to eq 2
    state, premises = matches.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'if true then false else true'
    expect(premises.length).to eq 2

    def derive(rules, expression, state)
      match_rules(rules, expression, state).flat_map { |state, premises|
        premises.inject([state]) { |states, premise|
          states.flat_map { |state| derive(rules, premise, state) }
        }
      }.compact
    end

    formula = parse('(if false then false else true) → _result')
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'true'

    formula = parse('(if (if true then true else false) then false else true) → _result')
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'if true then false else true'
    formula = evaluates(state.value_of(formula.find_variable('result')), parse('_result'))
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'false'

    formula = parse('(if (if (if true then false else true) then true else false) then false else true) → _result')
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'if (if false then true else false) then false else true'
    formula = evaluates(state.value_of(formula.find_variable('result')), parse('_result'))
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'if false then false else true'
    formula = evaluates(state.value_of(formula.find_variable('result')), parse('_result'))
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(formula.find_variable('result'))).to look_like 'true'

    NoRuleApplies = Class.new(StandardError)
    Nondeterministic = Class.new(StandardError)

    def eval1(rules, term)
      result = parse('_result')
      formula = evaluates(term, result)
      states = derive(rules, formula, State.new)

      raise NoRuleApplies if states.empty?
      raise Nondeterministic, states.map { |s| s.value_of(result) } if states.length > 1

      states.first.value_of(result)
    end

    RSpec::Matchers.define :reduce_to do |expected|
      match do |actual|
        eval1(rules, parse(actual)) == parse(expected)
      end
    end

    expect('if false then false else true').to reduce_to 'true'

    expect('if (if true then true else false) then false else true').to reduce_to 'if true then false else true'
    expect('if true then false else true').to reduce_to 'false'

    expect('if (if (if true then false else true) then true else false) then false else true').to reduce_to 'if (if false then true else false) then false else true'
    expect('if (if false then true else false) then false else true').to reduce_to 'if false then false else true'
    expect('if false then false else true').to reduce_to 'true'

    def evaluate(rules, term)
      begin
        evaluate(rules, eval1(rules, term))
      rescue NoRuleApplies
        term
      end
    end

    RSpec::Matchers.define :evaluate_to do |expected|
      match do |actual|
        @result = evaluate(rules, parse(actual))
        @result == parse(expected)
      end

      failure_message do |actual|
        %Q{expected "#{actual}" to evaluate to "#{expected}", but got "#{@result}" instead}
      end
    end

    expect('if false then false else true').to evaluate_to 'true'
    expect('if (if true then true else false) then false else true').to evaluate_to 'false'
    expect('if (if (if true then false else true) then true else false) then false else true').to evaluate_to 'true'

    rules += [
      rule([], '0 ∈ T'),
      rule(['_t₁ ∈ T'], '(succ _t₁) ∈ T'),
      rule(['_t₁ ∈ T'], '(pred _t₁) ∈ T'),
      rule(['_t₁ ∈ T'], '(iszero _t₁) ∈ T'),

      rule([], '0 ∈ NV'),
      rule(['_nv₁ ∈ NV'], '(succ _nv₁) ∈ NV'),

      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(succ _t₁) → (succ _t₁′)'),
      rule([], '(pred 0) → 0'),
      rule(['_nv₁ ∈ NV'], '(pred (succ _nv₁)) → _nv₁'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(pred _t₁) → (pred _t₁′)'),
      rule([], '(iszero 0) → true'),
      rule(['_nv₁ ∈ NV'], '(iszero (succ _nv₁)) → false'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(iszero _t₁) → (iszero _t₁′)')
    ]

    expect('pred (succ (succ 0))').to evaluate_to 'succ 0'
    expect('if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))').to evaluate_to '0'
    expect('pred (succ (succ (pred 0)))').to evaluate_to 'succ 0'
    expect('pred (succ (succ true))').to evaluate_to 'pred (succ (succ true))'
    expect('iszero 0').to evaluate_to 'true'
    expect('iszero (succ 0)').to evaluate_to 'false'
    expect('iszero (succ (succ (succ (succ 0))))').to evaluate_to 'false'
    expect('iszero (succ true)').to evaluate_to 'iszero (succ true)'
  end
end
