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
  end
end
