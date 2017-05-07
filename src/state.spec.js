import { parse } from './parser_helpers';
import State from './state';
import PrettyPrintingMatchers from './pretty_printing_matchers';

describe('state', () => {
  expect.extend(PrettyPrintingMatchers);

  const unify = (a, b) => new State().unify(a, b);

  describe('', () => {
    let term, state;

    beforeEach(() => {
      term = parse('$t₁');
      state = unify(term, parse('true'));
    });

    test('', () => {
      expect(state.valueOf(term.findVariable('t₁'))).toLookLike('true');
    });
  });

  describe('', () => {
    let term1, term2, state;

    beforeEach(() => {
      term1 = parse('$t₁');
      term2 = parse('$t₂');
      state = unify(term2, parse('false')).unify(term2, term1);
    });

    test('', () => {
      expect(state.valueOf(term1.findVariable('t₁'))).toLookLike('false');
    });
  });

  describe('', () => {
    let ifTrue, ifFalse, formula, state;

    beforeEach(() => {
      ifTrue = parse('(if true then $t₂ else $t₃) → $t₂');
      ifFalse = parse('(if false then $t₂ else $t₃) → $t₃');
      formula = parse('(if true then false else true) → $result');
    });

    describe('', () => {
      beforeEach(() => {
        state = unify(formula, ifTrue);
      });

      test('', () => {
        expect(state.valueOf(ifTrue.findVariable('t₂'))).toLookLike('false');
      });

      test('', () => {
        expect(state.valueOf(ifTrue.findVariable('t₃'))).toLookLike('true');
      });

      test('', () => {
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'false'
        );
      });
    });

    describe('', () => {
      beforeEach(() => {
        state = unify(formula, ifFalse);
      });

      test('', () => {
        expect(state).toBeUndefined();
      });
    });
  });

  describe('', () => {
    let ifTrue, ifFalse, formula, state;

    beforeEach(() => {
      ifTrue = parse('(if true then $t₂ else $t₃) → $t₂');
      ifFalse = parse('(if false then $t₂ else $t₃) → $t₃');
      formula = parse('(if false then false else true) → $result');
    });

    describe('', () => {
      beforeEach(() => {
        state = unify(formula, ifTrue);
      });

      test('', () => {
        expect(state).toBeUndefined();
      });
    });

    describe('', () => {
      beforeEach(() => {
        state = unify(formula, ifFalse);
      });

      test('', () => {
        expect(state.valueOf(ifFalse.findVariable('t₂'))).toLookLike('false');
      });

      test('', () => {
        expect(state.valueOf(ifFalse.findVariable('t₃'))).toLookLike('true');
      });

      test('', () => {
        expect(state.valueOf(formula.findVariable('result'))).toLookLike(
          'true'
        );
      });
    });
  });
});
