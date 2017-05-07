import Definition from './definition';
import { keyword, sequence } from './builder_helpers';
import { parse } from './parser_helpers';
import PrettyPrintingMatchers from './pretty_printing_matchers';
import { rule } from './rule_helpers';
import { List } from 'immutable';

describe('definition', () => {
  expect.extend(PrettyPrintingMatchers);

  const termSyntax = [
    rule([], 'true ∈ t'),
    rule([], 'false ∈ t'),
    rule(['$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t'], '(if $t₁ then $t₂ else $t₃) ∈ t')
  ];

  const semantics = [
    rule(['$t₂ ∈ t', '$t₃ ∈ t'], '(if true then $t₂ else $t₃) → $t₂'),
    rule(['$t₂ ∈ t', '$t₃ ∈ t'], '(if false then $t₂ else $t₃) → $t₃'),
    rule(
      ['$t₁ → $t₁′', '$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t', '$t₁′ ∈ t'],
      '(if $t₁ then $t₂ else $t₃) → (if $t₁′ then $t₂ else $t₃)'
    )
  ];

  const evaluates = (before, after) => sequence(before, keyword('→'), after);

  describe('boolean', () => {
    const definition = new Definition(List.of(...termSyntax, ...semantics));

    describe('matching', () => {
      test('', () => {
        const formula = parse('(if false then false else true) → $result');
        const matches = definition.matchRules(formula);
        expect(matches.size).toBe(2);
        const match = matches.first();
        expect(match.state.valueOf(formula.findVariable('result'))).toLookLike(
          'true'
        );
      });

      test('', () => {
        const formula = parse(
          '(if (if true then true else false) then false else true) → $result'
        );
        let matches = definition.matchRules(formula);
        expect(matches.size).toBe(1);
        let match = matches.first();
        expect(match.state.valueOf(formula.findVariable('result'))).toLookLike(
          'if $t₁′ then false else true'
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
        const formula = parse('(if false then false else true) → $result');
        const states = definition.derive(formula);
        expect(states.size).toBe(1);
        const state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'true'
        );
      });

      test('', () => {
        let formula = parse(
          '(if (if true then true else false) then false else true) → $result'
        );
        let states = definition.derive(formula);
        expect(states.size).toBe(1);
        let state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'if true then false else true'
        );
        formula = evaluates(
          state.valueOf(formula.findVariable('result')),
          parse('$result')
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
          '(if (if (if true then false else true) then true else false) then false else true) → $result'
        );
        let states = definition.derive(formula);
        expect(states.size).toBe(1);
        let state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'if (if false then true else false) then false else true'
        );
        formula = evaluates(
          state.valueOf(formula.findVariable('result')),
          parse('$result')
        );
        states = definition.derive(formula);
        expect(states.size).toBe(1);
        state = states.first();
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'if false then false else true'
        );
        formula = evaluates(
          state.valueOf(formula.findVariable('result')),
          parse('$result')
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
