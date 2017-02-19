require 'builder'
require 'formula'
require 'parser'
require 'rule'
require 'state'
require 'variable'

RSpec.describe do
  specify do
    RSpec::Matchers.define :look_like do |expected|
      match do |actual|
        actual.to_s == expected
      end
    end

    def parse(string)
      Parser.new(Builder.new).parse(string)
    end

    def parse_rule(premise_strings, conclusion_string)
      builder = Builder.new
      premises = premise_strings.map { |string| Parser.new(builder).parse(string) }
      conclusion = Parser.new(builder).parse(conclusion_string)

      Rule.new(premises, conclusion)
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

    def evaluates(before, after)
      Builder.new.build_formula([before, symbol('→'), after])
    end

    expect(parse('true')).to eq yes
    expect(parse('if false then false else true')).to eq conditional(no, no, yes)
    expect(parse('if (if true then true else false) then false else true')).to eq conditional(conditional(yes, yes, no), no, yes)

    expect(parse('(if true then _t₂ else _t₃) → _t₂')).to look_like 'if true then t₂ else t₃ → t₂'
    expect(parse('(if false then _t₂ else _t₃) → _t₃')).to look_like 'if false then t₂ else t₃ → t₃'

    expect(parse('_t₁ → _t₁′')).to look_like 't₁ → t₁′'
    expect(parse('(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)')).to look_like 'if t₁ then t₂ else t₃ → if t₁′ then t₂ else t₃'

    def find_variable(formula, name)
      case formula
      when Variable
        formula if formula.name == name
      when Formula
        formula.parts.each do |part|
          result = find_variable(part, name)
          return result if result
        end
        nil
      end
    end

    term = parse('_t₁')
    state = State.new.unify(term, parse('true'))
    expect(state.value_of(find_variable(term, 't₁'))).to look_like 'true'

    term₁ = parse('_t₁')
    term₂ = parse('_t₂')
    state = State.new.unify(term₂, parse('false')).unify(term₂, term₁)
    expect(state.value_of(find_variable(term₁, 't₁'))).to look_like 'false'

    if_true = parse('(if true then _t₂ else _t₃) → _t₂')
    if_false = parse('(if false then _t₂ else _t₃) → _t₃')
    formula = parse('(if true then false else true) → _result')
    state = State.new.unify(formula, if_true)
    expect(state.value_of(find_variable(if_true, 't₂'))).to look_like 'false'
    expect(state.value_of(find_variable(if_true, 't₃'))).to look_like 'true'
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'false'
    state = State.new.unify(formula, if_false)
    expect(state).to be_nil

    if_true = parse('(if true then _t₂ else _t₃) → _t₂')
    if_false = parse('(if false then _t₂ else _t₃) → _t₃')
    formula = parse('(if false then false else true) → _result')
    state = State.new.unify(formula, if_true)
    expect(state).to be_nil
    state = State.new.unify(formula, if_false)
    expect(state.value_of(find_variable(if_false, 't₂'))).to look_like 'false'
    expect(state.value_of(find_variable(if_false, 't₃'))).to look_like 'true'
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

    rules = [
      -> { parse_rule([], 'true ∈ T') },
      -> { parse_rule([], 'false ∈ T') },
      -> { parse_rule(['_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T'], '(if _t₁ then _t₂ else _t₃) ∈ T') },

      -> { parse_rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if true then _t₂ else _t₃) → _t₂') },
      -> { parse_rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if false then _t₂ else _t₃) → _t₃') },
      -> { parse_rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T', '_t₁′ ∈ T'], '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)') }
    ]

    def match_rules(rules, formula, state)
      rules.
        map(&:call).
        select { |rule| rule.matches?(formula, state) }.
        map { |rule| [rule, rule.match(formula, state)] }
    end

    formula = parse('(if false then false else true) → _result')
    state = State.new
    matches = match_rules(rules, formula, state)
    rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if false then' }
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

    formula = parse('(if (if true then true else false) then false else true) → _result')
    state = State.new
    matches = match_rules(rules, formula, state)
    rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if t₁ then' }
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if t₁′ then false else true'
    expect(rule.premises.length).to eq 5
    premise = rule.premises.first
    matches = match_rules(rules, premise, state)
    rule, state = matches.detect { |rule, _| rule.conclusion.to_s.start_with? 'if true then' }
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if true then false else true'
    expect(rule.premises.length).to eq 2

    def derive(rules, formula, state)
      match_rules(rules, formula, state).flat_map { |rule, state|
        rule.premises.inject([state]) { |states, premise|
          states.flat_map { |state| derive(rules, premise, state) }
        }
      }.compact
    end

    formula = parse('(if false then false else true) → _result')
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

    formula = parse('(if (if true then true else false) then false else true) → _result')
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if true then false else true'
    formula = evaluates(state.value_of(find_variable(formula, 'result')), parse('_result'))
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'false'

    formula = parse('(if (if (if true then false else true) then true else false) then false else true) → _result')
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if if false then true else false then false else true'
    formula = evaluates(state.value_of(find_variable(formula, 'result')), parse('_result'))
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'if false then false else true'
    formula = evaluates(state.value_of(find_variable(formula, 'result')), parse('_result'))
    states = derive(rules, formula, State.new)
    expect(states.length).to eq 1
    state = states.first
    expect(state.value_of(find_variable(formula, 'result'))).to look_like 'true'

    NoRuleApplies = Class.new(StandardError)
    Nondeterministic = Class.new(StandardError)

    def eval1(rules, term)
      result = parse('_result')
      formula = evaluates(term, result)
      states = derive(rules, formula, State.new)

      raise NoRuleApplies if states.empty?
      raise Nondeterministic, states.map { |s| s.value_of(result) } if states.length > 1

      states.first.value_of(result)
    end

    RSpec::Matchers.define :reduce_to do |expected|
      match do |actual|
        eval1(rules, parse(actual)) == parse(expected)
      end
    end

    expect('if false then false else true').to reduce_to 'true'

    expect('if (if true then true else false) then false else true').to reduce_to 'if true then false else true'
    expect('if true then false else true').to reduce_to 'false'

    expect('if (if (if true then false else true) then true else false) then false else true').to reduce_to 'if (if false then true else false) then false else true'
    expect('if (if false then true else false) then false else true').to reduce_to 'if false then false else true'
    expect('if false then false else true').to reduce_to 'true'

    def evaluate(rules, term)
      begin
        evaluate(rules, eval1(rules, term))
      rescue NoRuleApplies
        term
      end
    end

    RSpec::Matchers.define :evaluate_to do |expected|
      match do |actual|
        @result = evaluate(rules, parse(actual))
        @result == parse(expected)
      end

      failure_message do |actual|
        %Q{expected "#{actual}" to evaluate to "#{expected}", but got "#{@result}" instead}
      end
    end

    expect('if false then false else true').to evaluate_to 'true'
    expect('if (if true then true else false) then false else true').to evaluate_to 'false'
    expect('if (if (if true then false else true) then true else false) then false else true').to evaluate_to 'true'

    rules += [
      -> { parse_rule([], '0 ∈ T') },
      -> { parse_rule(['_t₁ ∈ T'], '(succ _t₁) ∈ T') },
      -> { parse_rule(['_t₁ ∈ T'], '(pred _t₁) ∈ T') },
      -> { parse_rule(['_t₁ ∈ T'], '(iszero _t₁) ∈ T') },

      -> { parse_rule([], '0 ∈ NV') },
      -> { parse_rule(['_nv₁ ∈ NV'], '(succ _nv₁) ∈ NV') },

      -> { parse_rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(succ _t₁) → (succ _t₁′)') },
      -> { parse_rule([], '(pred 0) → 0') },
      -> { parse_rule(['_nv₁ ∈ NV'], '(pred (succ _nv₁)) → _nv₁') },
      -> { parse_rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(pred _t₁) → (pred _t₁′)') },
      -> { parse_rule([], '(iszero 0) → true') },
      -> { parse_rule(['_nv₁ ∈ NV'], '(iszero (succ _nv₁)) → false') },
      -> { parse_rule(['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'], '(iszero _t₁) → (iszero _t₁′)') }
    ]

    expect('pred (succ (succ 0))').to evaluate_to 'succ 0'
    expect('if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))').to evaluate_to '0'
    expect('pred (succ (succ (pred 0)))').to evaluate_to 'succ 0'
    expect('pred (succ (succ true))').to evaluate_to 'pred (succ (succ true))'
    expect('iszero 0').to evaluate_to 'true'
    expect('iszero (succ 0)').to evaluate_to 'false'
    expect('iszero (succ (succ (succ (succ 0))))').to evaluate_to 'false'
    expect('iszero (succ true)').to evaluate_to 'iszero (succ true)'
  end
end
