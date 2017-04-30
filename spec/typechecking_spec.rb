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

  let(:lambda_calculus_term_syntax) {[
    { conclusion: 'a ∈ x' },
    { conclusion: 'b ∈ x' },
    { conclusion: 'c ∈ x' },
    { conclusion: 'd ∈ x' },
    { conclusion: 'e ∈ x' },
    { conclusion: 'f ∈ x' },
    { conclusion: 'g ∈ x' },
    { conclusion: 'x ∈ x' },
    { conclusion: 'y ∈ x' },
    { conclusion: 'z ∈ x' },

    {
      premises: ['_x ∈ x'],
      conclusion: '_x ∈ t'
    },
    {
      premises: ['_x ∈ x', '_T ∈ T', '_t ∈ t'],
      conclusion: '(λ _x : _T . _t) ∈ t'
    },
    {
      premises: ['_t₁ ∈ t', '_t₂ ∈ t'],
      conclusion: '(_t₁ _t₂) ∈ t'
    }
  ]}

  let(:lambda_calculus_type_syntax) {[
    {
      premises: ['_T₁ ∈ T', '_T₂ ∈ T'],
      conclusion: '(_T₁ → _T₂) ∈ T'
    }
  ]}

  let(:lambda_calculus_typing_context_rules) {[
    { conclusion: '∅ ∈ Г' },
    {
      premises: ['_x ∈ x', '_T ∈ T', '_Г ∈ Г'],
      conclusion: '(_x : _T , _Г) ∈ Г'
    },
    {
      premises: ['_x ∈ x', '_T ∈ T', '_Г ∈ Г'],
      conclusion: '(_x : _T , _Г) assumes (_x : _T)'
    },
    {
      premises: ['_Г assumes (_x₂ : _T₂)', '_x₁ ∈ x', '_x₂ ∈ x', '_T₁ ∈ T', '_T₂ ∈ T', '_Г ∈ Г'],
      conclusion: '(_x₁ : _T₁ , _Г) assumes (_x₂ : _T₂)'
    }
  ]}

  let(:lambda_calculus_type_rules) {[
    {
      premises: ['_Г ∈ Г'],
      conclusion: '_Г ⊢ true : Bool'
    },
    {
      premises: ['_Г ∈ Г'],
      conclusion: '_Г ⊢ false : Bool'
    },
    {
      premises: ['_Г ⊢ _t₁ : Bool', '_Г ⊢ _t₂ : _T', '_Г ⊢ _t₃ : _T', '_Г ∈ Г', '_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t', '_T ∈ T'],
      conclusion: '_Г ⊢ (if _t₁ then _t₂ else _t₃) : _T'
    },

    {
      premises: ['_Г assumes (_x : _T)', '_x ∈ x', '_T ∈ T', '_Г ∈ Г'],
      conclusion: '_Г ⊢ _x : _T'
    },
    {
      premises: ['(_x : _T₁ , _Г) ⊢ _t₂ : _T₂', '_Г ∈ Г', '_x ∈ x', '_T₁ ∈ T', '_t₂ ∈ t', '_T₂ ∈ T'],
      conclusion: '_Г ⊢ (λ _x : _T₁ . _t₂) : (_T₁ → _T₂)'
    },
    {
      premises: ['_Г ⊢ _t₁ : (_T₁₁ → _T₁₂)', '_Г ⊢ _t₂ : _T₁₁', '_Г ∈ Г', '_t₁ ∈ t', '_T₁₁ ∈ T', '_T₁₂ ∈ T', '_t₂ ∈ t'],
      conclusion: '_Г ⊢ (_t₁ _t₂) : _T₁₂'
    }
  ]}

  describe 'lambda calculus expressions' do
    let(:lambda_calculus_typechecking) {
      Relation.define name: %w(⊢ :),
        rules: boolean_term_syntax + lambda_calculus_term_syntax +
               boolean_type_syntax + lambda_calculus_type_syntax +
               lambda_calculus_typing_context_rules + lambda_calculus_type_rules
    }

    matcher :typecheck do
      match do |actual|
        actual_context = parse(context || '∅')
        actual_term = parse(actual)

        begin
          actual_type = lambda_calculus_typechecking.once(actual_context, actual_term)
        rescue Relation::NoRuleApplies
          return false
        end

        expected_type.nil? || actual_type == parse(expected_type)
      end

      chain :as, :expected_type
      chain :assuming, :context
    end

    describe do
      specify { expect('true').to typecheck.as('Bool') }
      specify { expect('a').to typecheck.as('Bool').assuming('(a : Bool , ∅)') }
      specify { expect('λ a : Bool . a').to typecheck.as('Bool → Bool') }
      specify { expect('a true').to typecheck.as('Bool').assuming('(a : (Bool → Bool) , ∅)') }

      specify { expect('(λ a : Bool . a) true').to typecheck.as 'Bool' }
      specify { expect('(λ a : (Bool → Bool) . a) (λ b : Bool . b)').to typecheck.as 'Bool → Bool' }
      specify { expect('(λ a : Bool . a) (λ b : Bool . b)').not_to typecheck }

      specify { expect('f (if false then true else false)').not_to typecheck }
      specify { expect('f (if false then true else false)').to typecheck.as('Bool').assuming('(f : (Bool → Bool) , ∅)') }

      specify { expect('λ x : Bool . (f (if x then false else x))').not_to typecheck }
      specify { expect('λ x : Bool . (f (if x then false else x))').to typecheck.as('Bool → Bool').assuming('(f : (Bool → Bool) , ∅)') }
    end
  end
end
