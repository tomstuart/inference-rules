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
      rule(['$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t'], '(if $t₁ then $t₂ else $t₃) ∈ t')
    ]
  }

  let(:boolean_semantics) {
    [
      rule(['$t₂ ∈ t', '$t₃ ∈ t'], '(if true then $t₂ else $t₃) → $t₂'),
      rule(['$t₂ ∈ t', '$t₃ ∈ t'], '(if false then $t₂ else $t₃) → $t₃'),
      rule(['$t₁ → $t₁′', '$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t', '$t₁′ ∈ t'], '(if $t₁ then $t₂ else $t₃) → (if $t₁′ then $t₂ else $t₃)')
    ]
  }

  let(:arithmetic_term_syntax) {
    [
      rule([], '0 ∈ t'),
      rule(['$t₁ ∈ t'], '(succ $t₁) ∈ t'),
      rule(['$t₁ ∈ t'], '(pred $t₁) ∈ t'),
      rule(['$t₁ ∈ t'], '(iszero $t₁) ∈ t'),

      rule([], '0 ∈ nv'),
      rule(['$nv₁ ∈ nv'], '(succ $nv₁) ∈ nv')
    ]
  }

  let(:arithmetic_semantics) {
    [
      rule(['$t₁ → $t₁′', '$t₁ ∈ t', '$t₁′ ∈ t'], '(succ $t₁) → (succ $t₁′)'),
      rule([], '(pred 0) → 0'),
      rule(['$nv₁ ∈ nv'], '(pred (succ $nv₁)) → $nv₁'),
      rule(['$t₁ → $t₁′', '$t₁ ∈ t', '$t₁′ ∈ t'], '(pred $t₁) → (pred $t₁′)'),
      rule([], '(iszero 0) → true'),
      rule(['$nv₁ ∈ nv'], '(iszero (succ $nv₁)) → false'),
      rule(['$t₁ → $t₁′', '$t₁ ∈ t', '$t₁′ ∈ t'], '(iszero $t₁) → (iszero $t₁′)')
    ]
  }

  def evaluates(before, after)
    sequence(before, keyword('→'), after)
  end

  describe 'boolean' do
    let(:definition) { Definition.new(boolean_term_syntax + boolean_semantics) }

    describe 'matching' do
      specify do
        formula = parse('(if false then false else true) → $result')
        matches = definition.match_rules(formula)
        expect(matches.length).to eq 2
        match = matches.first
        expect(match.state.value_of(formula.find_variable('result'))).to look_like 'true'
      end

      specify do
        formula = parse('(if (if true then true else false) then false else true) → $result')
        matches = definition.match_rules(formula)
        expect(matches.length).to eq 1
        match = matches.first
        expect(match.state.value_of(formula.find_variable('result'))).to look_like 'if $t₁′ then false else true'
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
        formula = parse('(if false then false else true) → $result')
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'true'
      end

      specify do
        formula = parse('(if (if true then true else false) then false else true) → $result')
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'if true then false else true'
        formula = evaluates(state.value_of(formula.find_variable('result')), parse('$result'))
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'false'
      end

      specify do
        formula = parse('(if (if (if true then false else true) then true else false) then false else true) → $result')
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'if (if false then true else false) then false else true'
        formula = evaluates(state.value_of(formula.find_variable('result')), parse('$result'))
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'if false then false else true'
        formula = evaluates(state.value_of(formula.find_variable('result')), parse('$result'))
        states = definition.derive(formula)
        expect(states.length).to eq 1
        state = states.first
        expect(state.value_of(formula.find_variable('result'))).to look_like 'true'
      end
    end
  end
end
