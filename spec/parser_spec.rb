require 'support/builder_helpers'
require 'support/parser_helpers'
require 'support/pretty_printing_matchers'

RSpec.describe do
  include BuilderHelpers
  include ParserHelpers
  include PrettyPrintingMatchers

  specify do
    def yes
      word('true')
    end

    def no
      word('false')
    end

    def conditional(condition, consequent, alternative)
      sequence(
        word('if'),   condition,
        word('then'), consequent,
        word('else'), alternative
      )
    end

    expect(parse('true')).to eq yes
    expect(parse('if false then false else true')).to eq conditional(no, no, yes)
    expect(parse('if (if true then true else false) then false else true')).to eq conditional(conditional(yes, yes, no), no, yes)

    expect(parse('(if true then _t₂ else _t₃) → _t₂')).to look_like '(if true then _t₂ else _t₃) → _t₂'
    expect(parse('(if false then _t₂ else _t₃) → _t₃')).to look_like '(if false then _t₂ else _t₃) → _t₃'

    expect(parse('_t₁ → _t₁′')).to look_like '_t₁ → _t₁′'
    expect(parse('(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)')).to look_like '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)'
  end
end
