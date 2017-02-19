require 'support/builder_helpers'
require 'support/parser_helpers'

RSpec.describe do
  include BuilderHelpers
  include ParserHelpers

  def yes
    keyword('true')
  end

  def no
    keyword('false')
  end

  def conditional(condition, consequent, alternative)
    sequence(
      keyword('if'),   condition,
      keyword('then'), consequent,
      keyword('else'), alternative
    )
  end

  def evaluates(before, after)
    sequence(before, keyword('→'), after)
  end

  describe 'without variables' do
    specify { expect(parse('true')).to eq yes }
    specify { expect(parse('if false then false else true')).to eq conditional(no, no, yes) }
    specify { expect(parse('if (if true then true else false) then false else true')).to eq conditional(conditional(yes, yes, no), no, yes) }
  end

  describe 'with variables' do
    let(:scope) { double }

    specify { expect(parse('(if true then _t₂ else _t₃) → _t₂', scope)).to eq evaluates(conditional(yes, variable('t₂', scope), variable('t₃', scope)), variable('t₂', scope)) }
    specify { expect(parse('(if false then _t₂ else _t₃) → _t₃', scope)).to eq evaluates(conditional(no, variable('t₂', scope), variable('t₃', scope)), variable('t₃', scope)) }
    specify { expect(parse('_t₁ → _t₁′', scope)).to eq evaluates(variable('t₁', scope), variable('t₁′', scope)) }
    specify { expect(parse('(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)', scope)).to eq evaluates(conditional(variable('t₁', scope), variable('t₂', scope), variable('t₃', scope)), conditional(variable('t₁′', scope), variable('t₂', scope), variable('t₃', scope))) }
  end
end
