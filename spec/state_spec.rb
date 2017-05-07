require 'state'

require 'support/parser_helpers'
require 'support/pretty_printing_matchers'

RSpec.describe do
  include ParserHelpers
  include PrettyPrintingMatchers

  def unify(a, b)
    State.new.unify(a, b)
  end

  describe do
    let(:term) { parse('$t₁') }
    let(:state) { unify(term, parse('true')) }

    specify { expect(state.value_of(term.find_variable('t₁'))).to look_like 'true' }
  end

  describe do
    let(:term₁) { parse('$t₁') }
    let(:term₂) { parse('$t₂') }
    let(:state) { unify(term₂, parse('false')).unify(term₂, term₁) }

    specify { expect(state.value_of(term₁.find_variable('t₁'))).to look_like 'false' }
  end

  describe do
    let(:if_true) { parse('(if true then $t₂ else $t₃) → $t₂') }
    let(:if_false) { parse('(if false then $t₂ else $t₃) → $t₃') }
    let(:formula) { parse('(if true then false else true) → $result') }

    describe do
      let(:state) { unify(formula, if_true) }

      specify { expect(state.value_of(if_true.find_variable('t₂'))).to look_like 'false' }
      specify { expect(state.value_of(if_true.find_variable('t₃'))).to look_like 'true' }
      specify { expect(state.value_of(formula.find_variable('result'))).to look_like 'false' }
    end

    describe do
      let(:state) { unify(formula, if_false) }

      specify { expect(state).to be_nil }
    end
  end

  describe do
    let(:if_true) { parse('(if true then $t₂ else $t₃) → $t₂') }
    let(:if_false) { parse('(if false then $t₂ else $t₃) → $t₃') }
    let(:formula) { parse('(if false then false else true) → $result') }

    describe do
      let(:state) { unify(formula, if_true) }

      specify { expect(state).to be_nil }
    end

    describe do
      let(:state) { unify(formula, if_false) }

      specify { expect(state.value_of(if_false.find_variable('t₂'))).to look_like 'false' }
      specify { expect(state.value_of(if_false.find_variable('t₃'))).to look_like 'true' }
      specify { expect(state.value_of(formula.find_variable('result'))).to look_like 'true' }
    end
  end
end
