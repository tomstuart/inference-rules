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

  let(:boolean_term_syntax) {
    [
      rule([], 'true ∈ t'),
      rule([], 'false ∈ t'),
      rule(['_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t'], '(if _t₁ then _t₂ else _t₃) ∈ t')
    ]
  }

  let(:boolean_semantics) {
    [
      rule(['_t₂ ∈ t', '_t₃ ∈ t'], '(if true then _t₂ else _t₃) → _t₂'),
      rule(['_t₂ ∈ t', '_t₃ ∈ t'], '(if false then _t₂ else _t₃) → _t₃'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t', '_t₁′ ∈ t'], '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)')
    ]
  }

  let(:arithmetic_term_syntax) {
    [
      rule([], '0 ∈ t'),
      rule(['_t₁ ∈ t'], '(succ _t₁) ∈ t'),
      rule(['_t₁ ∈ t'], '(pred _t₁) ∈ t'),
      rule(['_t₁ ∈ t'], '(iszero _t₁) ∈ t'),

      rule([], '0 ∈ nv'),
      rule(['_nv₁ ∈ nv'], '(succ _nv₁) ∈ nv')
    ]
  }

  let(:arithmetic_semantics) {
    [
      rule(['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'], '(succ _t₁) → (succ _t₁′)'),
      rule([], '(pred 0) → 0'),
      rule(['_nv₁ ∈ nv'], '(pred (succ _nv₁)) → _nv₁'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'], '(pred _t₁) → (pred _t₁′)'),
      rule([], '(iszero 0) → true'),
      rule(['_nv₁ ∈ nv'], '(iszero (succ _nv₁)) → false'),
      rule(['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'], '(iszero _t₁) → (iszero _t₁′)')
    ]
  }

  def evaluates(before, after)
    sequence(before, keyword('→'), after)
  end

  describe 'boolean' do
    let(:definition) { Definition.new(boolean_term_syntax + boolean_semantics) }

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
