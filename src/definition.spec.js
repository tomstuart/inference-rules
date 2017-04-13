import Definition from './definition';
import { keyword, sequence } from './builder_helpers';
import { parse } from './parser_helpers';
import PrettyPrintingMatchers from './pretty_printing_matchers';
import { rule } from './rule_helpers';
import { List } from 'immutable';

describe('definition', () => {
  expect.extend(PrettyPrintingMatchers);

  const syntax = [
    rule([], 'true ∈ T'),
    rule([], 'false ∈ T'),
    rule(['_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T'], '(if _t₁ then _t₂ else _t₃) ∈ T')
  ];

  const semantics = [
    rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if true then _t₂ else _t₃) → _t₂'),
    rule(['_t₂ ∈ T', '_t₃ ∈ T'], '(if false then _t₂ else _t₃) → _t₃'),
    rule(
      ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T', '_t₁′ ∈ T'],
      '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)'
    )
  ];

  const evaluates = (before, after) => sequence(before, keyword('→'), after);

  describe('boolean', () => {
    const definition = new Definition(List.of(...syntax, ...semantics));

    describe('matching', () => {
      test('', () => {
        const formula = parse('(if false then false else true) → _result');
        const matches = definition.matchRules(formula);
        expect(matches.size).toBe(2);
        const match = matches.first();
        expect(match.state.valueOf(formula.findVariable('result'))).toLookLike(
          'true'
        );
      });

      test('', () => {
        const formula = parse(
          '(if (if true then true else false) then false else true) → _result'
        );
        let matches = definition.matchRules(formula);
        expect(matches.size).toBe(1);
        let match = matches.first();
        expect(match.state.valueOf(formula.findVariable('result'))).toLookLike(
          'if _t₁′ then false else true'
        );
        expect(match.premises.size).toBe(5);
        const premise = match.premises.first();
        matches = definition.matchRules(premise, match.state);
        expect(matches.size).toBe(2);
        match = matches.first();
        expect(match.state.valueOf(formula.findVariable('result'))).toLookLike(
          'if true then false else true'
        );
        expect(match.premises.size).toBe(2);
      });
    });

    describe('deriving', () => {
      test('', () => {
        const formula = parse('(if false then false else true) → _result');
        const states = definition.derive(formula);
        expect(states.size).toBe(1);
        const state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'true'
        );
      });

      test('', () => {
        let formula = parse(
          '(if (if true then true else false) then false else true) → _result'
        );
        let states = definition.derive(formula);
        expect(states.size).toBe(1);
        let state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'if true then false else true'
        );
        formula = evaluates(
          state.valueOf(formula.findVariable('result')),
          parse('_result')
        );
        states = definition.derive(formula);
        expect(states.size).toBe(1);
        state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'false'
        );
      });

      test('', () => {
        let formula = parse(
          '(if (if (if true then false else true) then true else false) then false else true) → _result'
        );
        let states = definition.derive(formula);
        expect(states.size).toBe(1);
        let state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'if (if false then true else false) then false else true'
        );
        formula = evaluates(
          state.valueOf(formula.findVariable('result')),
          parse('_result')
        );
        states = definition.derive(formula);
        expect(states.size).toBe(1);
        state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'if false then false else true'
        );
        formula = evaluates(
          state.valueOf(formula.findVariable('result')),
          parse('_result')
        );
        states = definition.derive(formula);
        expect(states.size).toBe(1);
        state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'true'
        );
      });
    });
  });
});
