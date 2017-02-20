require 'relation'
require 'support/parser_helpers'

RSpec.describe 'evaluation' do
  include ParserHelpers

  let(:boolean_syntax) {[
    { conclusion: 'true ∈ T' },
    { conclusion: 'false ∈ T' },
    {
      premises: ['_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T'],
      conclusion: '(if _t₁ then _t₂ else _t₃) ∈ T'
    }
  ]}

  let(:boolean_semantics) {[
    {
      premises: ['_t₂ ∈ T', '_t₃ ∈ T'],
      conclusion: '(if true then _t₂ else _t₃) → _t₂'
    },
    {
      premises: ['_t₂ ∈ T', '_t₃ ∈ T'],
      conclusion: '(if false then _t₂ else _t₃) → _t₃'
    },
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T', '_t₁′ ∈ T'],
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
    { conclusion: '0 ∈ T' },
    { premises: ['_t₁ ∈ T'], conclusion: '(succ _t₁) ∈ T' },
    { premises: ['_t₁ ∈ T'], conclusion: '(pred _t₁) ∈ T' },
    { premises: ['_t₁ ∈ T'], conclusion: '(iszero _t₁) ∈ T' },

    { conclusion: '0 ∈ NV' },
    { premises: ['_nv₁ ∈ NV'], conclusion: '(succ _nv₁) ∈ NV' }
  ]}

  let(:arithmetic_semantics) {[
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'],
      conclusion: '(succ _t₁) → (succ _t₁′)'
    },
    { conclusion: '(pred 0) → 0' },
    {
      premises: ['_nv₁ ∈ NV'],
      conclusion: '(pred (succ _nv₁)) → _nv₁'
    },
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'],
      conclusion: '(pred _t₁) → (pred _t₁′)'
    },
    { conclusion: '(iszero 0) → true' },
    {
      premises: ['_nv₁ ∈ NV'],
      conclusion: '(iszero (succ _nv₁)) → false'
    },
    {
      premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'],
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
