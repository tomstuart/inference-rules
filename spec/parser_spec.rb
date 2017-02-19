require 'builder'
require 'parser'

RSpec.describe do
  specify do
    RSpec::Matchers.define :look_like do |expected|
      match do |actual|
        actual.to_s == expected
      end
    end

    def parse(string)
      Parser.parse(string)
    end

    def symbol(name)
      Builder.new.build_symbol(name)
    end

    def yes
      symbol('true')
    end

    def no
      symbol('false')
    end

    def conditional(condition, consequent, alternative)
      Builder.new.build_formula([
        symbol('if'),   condition,
        symbol('then'), consequent,
        symbol('else'), alternative
      ])
    end

    expect(parse('true')).to eq yes
    expect(parse('if false then false else true')).to eq conditional(no, no, yes)
    expect(parse('if (if true then true else false) then false else true')).to eq conditional(conditional(yes, yes, no), no, yes)

    expect(parse('(if true then _t₂ else _t₃) → _t₂')).to look_like 'if true then t₂ else t₃ → t₂'
    expect(parse('(if false then _t₂ else _t₃) → _t₃')).to look_like 'if false then t₂ else t₃ → t₃'

    expect(parse('_t₁ → _t₁′')).to look_like 't₁ → t₁′'
    expect(parse('(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)')).to look_like 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃'
  end
end
