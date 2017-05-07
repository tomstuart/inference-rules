require 'relation'
require 'support/parser_helpers'

RSpec.describe 'typechecking' do
  include ParserHelpers

  let(:boolean_term_syntax) {[
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: ['$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t'],
      conclusion: '(if $t₁ then $t₂ else $t₃) ∈ t'
    }
  ]}

  let(:boolean_type_syntax) {[
    { conclusion: 'Bool ∈ T' }
  ]}

  let(:boolean_type_rules) {[
    { conclusion: 'true : Bool' },
    { conclusion: 'false : Bool' },
    {
      premises: ['$t₁ : Bool', '$t₂ : $T', '$t₃ : $T', '$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t', '$T ∈ T'],
      conclusion: '(if $t₁ then $t₂ else $t₃) : $T'
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
    { premises: ['$t₁ ∈ t'], conclusion: '(succ $t₁) ∈ t' },
    { premises: ['$t₁ ∈ t'], conclusion: '(pred $t₁) ∈ t' },
    { premises: ['$t₁ ∈ t'], conclusion: '(iszero $t₁) ∈ t' },

    { conclusion: '0 ∈ nv' },
    { premises: ['$nv₁ ∈ nv'], conclusion: '(succ $nv₁) ∈ nv' }
  ]}

  let(:arithmetic_type_syntax) {[
    { conclusion: 'Nat ∈ T' }
  ]}

  let(:arithmetic_type_rules) {[
    { conclusion: '0 : Nat' },
    {
      premises: ['$t₁ : Nat', '$t₁ ∈ t'],
      conclusion: '(succ $t₁) : Nat'
    },
    {
      premises: ['$t₁ : Nat', '$t₁ ∈ t'],
      conclusion: '(pred $t₁) : Nat'
    },
    {
      premises: ['$t₁ : Nat', '$t₁ ∈ t'],
      conclusion: '(iszero $t₁) : Bool'
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
      premises: ['$x ∈ x'],
      conclusion: '$x ∈ t'
    },
    {
      premises: ['$x ∈ x', '$T ∈ T', '$t ∈ t'],
      conclusion: '(λ $x : $T . $t) ∈ t'
    },
    {
      premises: ['$t₁ ∈ t', '$t₂ ∈ t'],
      conclusion: '($t₁ $t₂) ∈ t'
    }
  ]}

  let(:lambda_calculus_type_syntax) {[
    {
      premises: ['$T₁ ∈ T', '$T₂ ∈ T'],
      conclusion: '($T₁ → $T₂) ∈ T'
    }
  ]}

  let(:lambda_calculus_typing_context_rules) {[
    { conclusion: '∅ ∈ Г' },
    {
      premises: ['$x ∈ x', '$T ∈ T', '$Г ∈ Г'],
      conclusion: '($x : $T , $Г) ∈ Г'
    },
    {
      premises: ['$x ∈ x', '$T ∈ T', '$Г ∈ Г'],
      conclusion: '($x : $T , $Г) assumes ($x : $T)'
    },
    {
      premises: ['$Г assumes ($x₂ : $T₂)', '$x₁ ∈ x', '$x₂ ∈ x', '$T₁ ∈ T', '$T₂ ∈ T', '$Г ∈ Г'],
      conclusion: '($x₁ : $T₁ , $Г) assumes ($x₂ : $T₂)'
    }
  ]}

  let(:lambda_calculus_type_rules) {[
    {
      premises: ['$Г ∈ Г'],
      conclusion: '$Г ⊢ true : Bool'
    },
    {
      premises: ['$Г ∈ Г'],
      conclusion: '$Г ⊢ false : Bool'
    },
    {
      premises: ['$Г ⊢ $t₁ : Bool', '$Г ⊢ $t₂ : $T', '$Г ⊢ $t₃ : $T', '$Г ∈ Г', '$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t', '$T ∈ T'],
      conclusion: '$Г ⊢ (if $t₁ then $t₂ else $t₃) : $T'
    },

    {
      premises: ['$Г assumes ($x : $T)', '$x ∈ x', '$T ∈ T', '$Г ∈ Г'],
      conclusion: '$Г ⊢ $x : $T'
    },
    {
      premises: ['($x : $T₁ , $Г) ⊢ $t₂ : $T₂', '$Г ∈ Г', '$x ∈ x', '$T₁ ∈ T', '$t₂ ∈ t', '$T₂ ∈ T'],
      conclusion: '$Г ⊢ (λ $x : $T₁ . $t₂) : ($T₁ → $T₂)'
    },
    {
      premises: ['$Г ⊢ $t₁ : ($T₁₁ → $T₁₂)', '$Г ⊢ $t₂ : $T₁₁', '$Г ∈ Г', '$t₁ ∈ t', '$T₁₁ ∈ T', '$T₁₂ ∈ T', '$t₂ ∈ t'],
      conclusion: '$Г ⊢ ($t₁ $t₂) : $T₁₂'
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
