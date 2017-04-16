require 'relation'
require 'support/parser_helpers'

RSpec.describe 'evaluation' do
  include ParserHelpers

  let(:boolean_syntax) {[
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: ['_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t'],
      conclusion: '(if _t₁ then _t₂ else _t₃) ∈ t'
    }
  ]}

  let(:boolean_semantics) {[
    {
      premises: ['_t₂ ∈ t', '_t₃ ∈ t'],
      conclusion: '(if true then _t₂ else _t₃) → _t₂'
    },
    {
      premises: ['_t₂ ∈ t', '_t₃ ∈ t'],
      conclusion: '(if false then _t₂ else _t₃) → _t₃'
    },
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t', '_t₁′ ∈ t'],
      conclusion: '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)'
    }
  ]}

  describe 'boolean expressions' do
    let(:boolean_evaluation) {
      Relation.define name: '→', rules: boolean_syntax + boolean_semantics
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

  let(:arithmetic_syntax) {[
    { conclusion: '0 ∈ t' },
    { premises: ['_t₁ ∈ t'], conclusion: '(succ _t₁) ∈ t' },
    { premises: ['_t₁ ∈ t'], conclusion: '(pred _t₁) ∈ t' },
    { premises: ['_t₁ ∈ t'], conclusion: '(iszero _t₁) ∈ t' },

    { conclusion: '0 ∈ nv' },
    { premises: ['_nv₁ ∈ nv'], conclusion: '(succ _nv₁) ∈ nv' }
  ]}

  let(:arithmetic_semantics) {[
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'],
      conclusion: '(succ _t₁) → (succ _t₁′)'
    },
    { conclusion: '(pred 0) → 0' },
    {
      premises: ['_nv₁ ∈ nv'],
      conclusion: '(pred (succ _nv₁)) → _nv₁'
    },
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'],
      conclusion: '(pred _t₁) → (pred _t₁′)'
    },
    { conclusion: '(iszero 0) → true' },
    {
      premises: ['_nv₁ ∈ nv'],
      conclusion: '(iszero (succ _nv₁)) → false'
    },
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'],
      conclusion: '(iszero _t₁) → (iszero _t₁′)'
    }
  ]}

  describe 'arithmetic expressions' do
    let(:arithmetic_evaluation) {
      Relation.define name: '→', rules: boolean_syntax + boolean_semantics + arithmetic_syntax + arithmetic_semantics
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
