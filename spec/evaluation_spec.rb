require 'relation'
require 'support/parser_helpers'

RSpec.describe 'evaluation' do
  include ParserHelpers

  let(:boolean_term_syntax) {[
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: ['$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t'],
      conclusion: '(if $t₁ then $t₂ else $t₃) ∈ t'
    }
  ]}

  let(:boolean_semantics) {[
    {
      premises: ['$t₂ ∈ t', '$t₃ ∈ t'],
      conclusion: '(if true then $t₂ else $t₃) → $t₂'
    },
    {
      premises: ['$t₂ ∈ t', '$t₃ ∈ t'],
      conclusion: '(if false then $t₂ else $t₃) → $t₃'
    },
    {
      premises: ['$t₁ → $t₁′', '$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t', '$t₁′ ∈ t'],
      conclusion: '(if $t₁ then $t₂ else $t₃) → (if $t₁′ then $t₂ else $t₃)'
    }
  ]}

  describe 'boolean expressions' do
    let(:boolean_evaluation) {
      Relation.define name: '→', rules: boolean_term_syntax + boolean_semantics
    }

    matcher :evaluate_to do |expected|
      match do |actual|
        boolean_evaluation.once(parse(actual)) == parse(expected)
      end
    end

    describe do
      specify { expect('if false then false else true').to evaluate_to 'true' }
    end

    describe do
      specify { expect('if (if true then true else false) then false else true').to evaluate_to 'if true then false else true' }
      specify { expect('if true then false else true').to evaluate_to 'false' }
    end

    describe do
      specify { expect('if (if (if true then false else true) then true else false) then false else true').to evaluate_to 'if (if false then true else false) then false else true' }
      specify { expect('if (if false then true else false) then false else true').to evaluate_to 'if false then false else true' }
      specify { expect('if false then false else true').to evaluate_to 'true' }
    end

    matcher :finally_evaluate_to do |expected|
      match do |actual|
        boolean_evaluation.many(parse(actual)) == parse(expected)
      end
    end

    specify { expect('if false then false else true').to finally_evaluate_to 'true' }
    specify { expect('if (if true then true else false) then false else true').to finally_evaluate_to 'false' }
    specify { expect('if (if (if true then false else true) then true else false) then false else true').to finally_evaluate_to 'true' }
  end

  let(:arithmetic_term_syntax) {[
    { conclusion: '0 ∈ t' },
    { premises: ['$t₁ ∈ t'], conclusion: '(succ $t₁) ∈ t' },
    { premises: ['$t₁ ∈ t'], conclusion: '(pred $t₁) ∈ t' },
    { premises: ['$t₁ ∈ t'], conclusion: '(iszero $t₁) ∈ t' },

    { conclusion: '0 ∈ nv' },
    { premises: ['$nv₁ ∈ nv'], conclusion: '(succ $nv₁) ∈ nv' }
  ]}

  let(:arithmetic_semantics) {[
    {
      premises: ['$t₁ → $t₁′', '$t₁ ∈ t', '$t₁′ ∈ t'],
      conclusion: '(succ $t₁) → (succ $t₁′)'
    },
    { conclusion: '(pred 0) → 0' },
    {
      premises: ['$nv₁ ∈ nv'],
      conclusion: '(pred (succ $nv₁)) → $nv₁'
    },
    {
      premises: ['$t₁ → $t₁′', '$t₁ ∈ t', '$t₁′ ∈ t'],
      conclusion: '(pred $t₁) → (pred $t₁′)'
    },
    { conclusion: '(iszero 0) → true' },
    {
      premises: ['$nv₁ ∈ nv'],
      conclusion: '(iszero (succ $nv₁)) → false'
    },
    {
      premises: ['$t₁ → $t₁′', '$t₁ ∈ t', '$t₁′ ∈ t'],
      conclusion: '(iszero $t₁) → (iszero $t₁′)'
    }
  ]}

  describe 'arithmetic expressions' do
    let(:arithmetic_evaluation) {
      Relation.define name: '→', rules: boolean_term_syntax + boolean_semantics + arithmetic_term_syntax + arithmetic_semantics
    }

    matcher :finally_evaluate_to do |expected|
      match do |actual|
        arithmetic_evaluation.many(parse(actual)) == parse(expected)
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
