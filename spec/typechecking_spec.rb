require 'relation'
require 'support/parser_helpers'

RSpec.describe 'typechecking' do
  include ParserHelpers

  let(:boolean_term_syntax) {[
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: ['_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t'],
      conclusion: '(if _t₁ then _t₂ else _t₃) ∈ t'
    }
  ]}

  let(:boolean_type_syntax) {[
    { conclusion: 'Bool ∈ T' }
  ]}

  let(:boolean_type_rules) {[
    { conclusion: 'true : Bool' },
    { conclusion: 'false : Bool' },
    {
      premises: ['_t₁ : Bool', '_t₂ : _T', '_t₃ : _T', '_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t', '_T ∈ T'],
      conclusion: '(if _t₁ then _t₂ else _t₃) : _T'
    }
  ]}

  describe 'boolean expressions' do
    let(:boolean_typechecking) {
      Relation.define name: ':', rules: boolean_term_syntax + boolean_type_syntax + boolean_type_rules
    }

    matcher :typecheck do
      match do |actual|
        actual_term = parse(actual)

        begin
          actual_type = boolean_typechecking.once(actual_term)
        rescue Relation::NoRuleApplies
          return false
        end

        expected_type.nil? || actual_type == parse(expected_type)
      end

      chain :as, :expected_type
    end

    describe do
      specify { expect('true').to typecheck.as 'Bool' }
      specify { expect('false').to typecheck.as 'Bool' }
      specify { expect('hello').not_to typecheck }
      specify { expect('if false then false else true').to typecheck.as 'Bool' }
      specify { expect('if false then hello else true').not_to typecheck }
      specify { expect('if (if (if true then false else true) then true else false) then false else true').to typecheck.as 'Bool' }
    end
  end

  let(:arithmetic_term_syntax) {[
    { conclusion: '0 ∈ t' },
    { premises: ['_t₁ ∈ t'], conclusion: '(succ _t₁) ∈ t' },
    { premises: ['_t₁ ∈ t'], conclusion: '(pred _t₁) ∈ t' },
    { premises: ['_t₁ ∈ t'], conclusion: '(iszero _t₁) ∈ t' },

    { conclusion: '0 ∈ nv' },
    { premises: ['_nv₁ ∈ nv'], conclusion: '(succ _nv₁) ∈ nv' }
  ]}

  let(:arithmetic_type_syntax) {[
    { conclusion: 'Nat ∈ T' }
  ]}

  let(:arithmetic_type_rules) {[
    { conclusion: '0 : Nat' },
    {
      premises: ['_t₁ : Nat', '_t₁ ∈ t'],
      conclusion: '(succ _t₁) : Nat'
    },
    {
      premises: ['_t₁ : Nat', '_t₁ ∈ t'],
      conclusion: '(pred _t₁) : Nat'
    },
    {
      premises: ['_t₁ : Nat', '_t₁ ∈ t'],
      conclusion: '(iszero _t₁) : Bool'
    }
  ]}

  describe 'arithmetic expressions' do
    let(:arithmetic_typechecking) {
      Relation.define name: ':', rules: boolean_term_syntax + boolean_type_syntax + boolean_type_rules + arithmetic_term_syntax + arithmetic_type_syntax + arithmetic_type_rules
    }

    matcher :typecheck do
      match do |actual|
        actual_term = parse(actual)

        begin
          actual_type = arithmetic_typechecking.once(actual_term)
        rescue Relation::NoRuleApplies
          return false
        end

        expected_type.nil? || actual_type == parse(expected_type)
      end

      chain :as, :expected_type
    end

    specify { expect('pred (succ (succ 0))').to typecheck.as 'Nat' }
    specify { expect('if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))').to typecheck.as 'Nat' }
    specify { expect('if (iszero (pred 0)) then (iszero 0) else (iszero (succ 0))').to typecheck.as 'Bool' }
    specify { expect('if (succ 0) then 0 else (succ 0)').not_to typecheck }
    specify { expect('if (iszero 0) then 0 else (iszero 0)').not_to typecheck }
    specify { expect('if (iszero true) then 0 else (succ 0)').not_to typecheck }
  end
end
