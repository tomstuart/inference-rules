require 'state'

require 'support/parser_helpers'
require 'support/pretty_printing_matchers'

RSpec.describe do
  include ParserHelpers
  include PrettyPrintingMatchers

  describe do
    let(:term) { parse('_t₁') }
    let(:state) { State.new.unify(term, parse('true')) }

    specify { expect(state.value_of(term.find_variable('t₁'))).to look_like 'true' }
  end

  describe do
    let(:term₁) { parse('_t₁') }
    let(:term₂) { parse('_t₂') }
    let(:state) { State.new.unify(term₂, parse('false')).unify(term₂, term₁) }

    specify { expect(state.value_of(term₁.find_variable('t₁'))).to look_like 'false' }
  end

  describe do
    let(:if_true) { parse('(if true then _t₂ else _t₃) → _t₂') }
    let(:if_false) { parse('(if false then _t₂ else _t₃) → _t₃') }
    let(:formula) { parse('(if true then false else true) → _result') }

    describe do
      let(:state) { State.new.unify(formula, if_true) }

      specify { expect(state.value_of(if_true.find_variable('t₂'))).to look_like 'false' }
      specify { expect(state.value_of(if_true.find_variable('t₃'))).to look_like 'true' }
      specify { expect(state.value_of(formula.find_variable('result'))).to look_like 'false' }
    end

    describe do
      let(:state) { State.new.unify(formula, if_false) }

      specify { expect(state).to be_nil }
    end
  end

  describe do
    let(:if_true) { parse('(if true then _t₂ else _t₃) → _t₂') }
    let(:if_false) { parse('(if false then _t₂ else _t₃) → _t₃') }
    let(:formula) { parse('(if false then false else true) → _result') }

    describe do
      let(:state) { State.new.unify(formula, if_true) }

      specify { expect(state).to be_nil }
    end

    describe do
      let(:state) { State.new.unify(formula, if_false) }

      specify { expect(state.value_of(if_false.find_variable('t₂'))).to look_like 'false' }
      specify { expect(state.value_of(if_false.find_variable('t₃'))).to look_like 'true' }
      specify { expect(state.value_of(formula.find_variable('result'))).to look_like 'true' }
    end
  end
end
