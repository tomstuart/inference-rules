require 'definition'

require 'support/builder_helpers'
require 'support/parser_helpers'
require 'support/pretty_printing_matchers'
require 'support/rule_helpers'

RSpec.describe do
  include BuilderHelpers
  include ParserHelpers
  include PrettyPrintingMatchers
  include RuleHelpers

  let(:boolean_syntax) {
    [
      rule([], 'true ∈ T'),
      rule([], 'false ∈ T'),
      rule(['_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T'], '(if _t₁ then _t₂ else _t₃) ∈ T')
    ]
  }

  let(:boolean_semantics) {
    [
      rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if true then _t₂ else _t₃) → _t₂'),
      rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if false then _t₂ else _t₃) → _t₃'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T', '_t₁′ ∈ T'], '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)')
    ]
  }

  let(:arithmetic_syntax) {
    [
      rule([], '0 ∈ T'),
      rule(['_t₁ ∈ T'], '(succ _t₁) ∈ T'),
      rule(['_t₁ ∈ T'], '(pred _t₁) ∈ T'),
      rule(['_t₁ ∈ T'], '(iszero _t₁) ∈ T'),

      rule([], '0 ∈ NV'),
      rule(['_nv₁ ∈ NV'], '(succ _nv₁) ∈ NV')
    ]
  }

  let(:arithmetic_semantics) {
    [
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(succ _t₁) → (succ _t₁′)'),
      rule([], '(pred 0) → 0'),
      rule(['_nv₁ ∈ NV'], '(pred (succ _nv₁)) → _nv₁'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(pred _t₁) → (pred _t₁′)'),
      rule([], '(iszero 0) → true'),
      rule(['_nv₁ ∈ NV'], '(iszero (succ _nv₁)) → false'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(iszero _t₁) → (iszero _t₁′)')
    ]
  }

  def evaluates(before, after)
    sequence(before, keyword('→'), after)
  end

  NoRuleApplies = Class.new(StandardError)
  Nondeterministic = Class.new(StandardError)

  def eval1(definition, term)
    result = parse('_result')
    formula = evaluates(term, result)
    states = definition.derive(formula)

    raise NoRuleApplies if states.empty?
    raise Nondeterministic, states.map { |s| s.value_of(result) } if states.length > 1

    states.first.value_of(result)
  end

  def evaluate(definition, term)
    begin
      evaluate(definition, eval1(definition, term))
    rescue NoRuleApplies
      term
    end
  end

  describe 'boolean' do
    let(:definition) { Definition.new(boolean_syntax + boolean_semantics) }

    describe 'matching' do
      specify do
        formula = parse('(if false then false else true) → _result')
        matches = definition.match_rules(formula)
        expect(matches.length).to eq 2
        match = matches.first
        expect(match.state.value_of(formula.find_variable('result'))).to look_like 'true'
      end

      specify do
        formula = parse('(if (if true then true else false) then false else true) → _result')
        matches = definition.match_rules(formula)
        expect(matches.length).to eq 1
        match = matches.first
        expect(match.state.value_of(formula.find_variable('result'))).to look_like 'if _t₁′ then false else true'
        expect(match.premises.length).to eq 5
        premise = match.premises.first
        matches = definition.match_rules(premise, match.state)
        expect(matches.length).to eq 2
        match = matches.first
        expect(match.state.value_of(formula.find_variable('result'))).to look_like 'if true then false else true'
        expect(match.premises.length).to eq 2
      end
    end

    describe 'deriving' do
      specify do
        formula = parse('(if false then false else true) → _result')
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'true'
      end

      specify do
        formula = parse('(if (if true then true else false) then false else true) → _result')
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'if true then false else true'
        formula = evaluates(state.value_of(formula.find_variable('result')), parse('_result'))
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'false'
      end

      specify do
        formula = parse('(if (if (if true then false else true) then true else false) then false else true) → _result')
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'if (if false then true else false) then false else true'
        formula = evaluates(state.value_of(formula.find_variable('result')), parse('_result'))
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'if false then false else true'
        formula = evaluates(state.value_of(formula.find_variable('result')), parse('_result'))
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'true'
      end
    end

    describe 'evaluating' do
      matcher :evaluate_to do |expected|
        match do |actual|
          eval1(definition, parse(actual)) == parse(expected)
        end
      end

      specify do
        expect('if false then false else true').to evaluate_to 'true'
      end

      specify do
        expect('if (if true then true else false) then false else true').to evaluate_to 'if true then false else true'
        expect('if true then false else true').to evaluate_to 'false'
      end

      specify do
        expect('if (if (if true then false else true) then true else false) then false else true').to evaluate_to 'if (if false then true else false) then false else true'
        expect('if (if false then true else false) then false else true').to evaluate_to 'if false then false else true'
        expect('if false then false else true').to evaluate_to 'true'
      end
    end

    describe 'finally evaluating' do
      matcher :finally_evaluate_to do |expected|
        match do |actual|
          evaluate(definition, parse(actual)) == parse(expected)
        end
      end

      specify { expect('if false then false else true').to finally_evaluate_to 'true' }
      specify { expect('if (if true then true else false) then false else true').to finally_evaluate_to 'false' }
      specify { expect('if (if (if true then false else true) then true else false) then false else true').to finally_evaluate_to 'true' }
    end
  end

  describe 'arithmetic' do
    let(:definition) { Definition.new(boolean_syntax + boolean_semantics + arithmetic_syntax + arithmetic_semantics) }

    describe 'evaluating' do
      matcher :finally_evaluate_to do |expected|
        match do |actual|
          evaluate(definition, parse(actual)) == parse(expected)
        end
      end

      specify { expect('pred (succ (succ 0))').to finally_evaluate_to 'succ 0' }
      specify { expect('if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))').to finally_evaluate_to '0' }
      specify { expect('pred (succ (succ (pred 0)))').to finally_evaluate_to 'succ 0' }
      specify { expect('pred (succ (succ true))').to finally_evaluate_to 'pred (succ (succ true))' }
      specify { expect('iszero 0').to finally_evaluate_to 'true' }
      specify { expect('iszero (succ 0)').to finally_evaluate_to 'false' }
      specify { expect('iszero (succ (succ (succ (succ 0))))').to finally_evaluate_to 'false' }
      specify { expect('iszero (succ true)').to finally_evaluate_to 'iszero (succ true)' }
    end
  end
end
