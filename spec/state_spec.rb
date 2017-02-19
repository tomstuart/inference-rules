require 'state'

require 'support/parser_helpers'
require 'support/pretty_printing_matchers'

RSpec.describe do
  include ParserHelpers
  include PrettyPrintingMatchers

  specify do
    term = parse('_t₁')
    state = State.new.unify(term, parse('true'))
    expect(state.value_of(term.find_variable('t₁'))).to look_like 'true'

    term₁ = parse('_t₁')
    term₂ = parse('_t₂')
    state = State.new.unify(term₂, parse('false')).unify(term₂, term₁)
    expect(state.value_of(term₁.find_variable('t₁'))).to look_like 'false'

    if_true = parse('(if true then _t₂ else _t₃) → _t₂')
    if_false = parse('(if false then _t₂ else _t₃) → _t₃')
    formula = parse('(if true then false else true) → _result')
    state = State.new.unify(formula, if_true)
    expect(state.value_of(if_true.find_variable('t₂'))).to look_like 'false'
    expect(state.value_of(if_true.find_variable('t₃'))).to look_like 'true'
    expect(state.value_of(formula.find_variable('result'))).to look_like 'false'
    state = State.new.unify(formula, if_false)
    expect(state).to be_nil

    if_true = parse('(if true then _t₂ else _t₃) → _t₂')
    if_false = parse('(if false then _t₂ else _t₃) → _t₃')
    formula = parse('(if false then false else true) → _result')
    state = State.new.unify(formula, if_true)
    expect(state).to be_nil
    state = State.new.unify(formula, if_false)
    expect(state.value_of(if_false.find_variable('t₂'))).to look_like 'false'
    expect(state.value_of(if_false.find_variable('t₃'))).to look_like 'true'
    expect(state.value_of(formula.find_variable('result'))).to look_like 'true'
  end
end
