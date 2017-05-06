import Relation from './relation';
import { parse } from './parser_helpers';
import { List } from 'immutable';

describe('evaluation', () => {
  const booleanTermSyntax = [
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: List.of('_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t'),
      conclusion: '(if _t₁ then _t₂ else _t₃) ∈ t'
    }
  ];

  const booleanSemantics = [
    {
      premises: List.of('_t₂ ∈ t', '_t₃ ∈ t'),
      conclusion: '(if true then _t₂ else _t₃) → _t₂'
    },
    {
      premises: List.of('_t₂ ∈ t', '_t₃ ∈ t'),
      conclusion: '(if false then _t₂ else _t₃) → _t₃'
    },
    {
      premises: List.of(
        '_t₁ → _t₁′',
        '_t₁ ∈ t',
        '_t₂ ∈ t',
        '_t₃ ∈ t',
        '_t₁′ ∈ t'
      ),
      conclusion: '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)'
    }
  ];

  describe('boolean expressions', () => {
    let booleanEvaluation = Relation.define({
      name: '→',
      rules: List.of(...booleanTermSyntax, ...booleanSemantics)
    });

    expect.extend({
      toEvaluateTo(before, after) {
        const actual = booleanEvaluation.once(parse(before));
        const expected = parse(after);

        if (actual.equals(expected)) {
          return {
            pass: true,
            message: `expected ${before} not to evaluate to “${after}”`
          };
        } else {
          return {
            pass: false,
            message: `expected ${before} to evaluate to “${after}”, but got “${actual}”`
          };
        }
      }
    });

    describe('', () => {
      test('', () => {
        expect('if false then false else true').toEvaluateTo('true');
      });
    });

    describe('', () => {
      test('', () => {
        expect(
          'if (if true then true else false) then false else true'
        ).toEvaluateTo('if true then false else true');
      });

      test('', () => {
        expect('if true then false else true').toEvaluateTo('false');
      });
    });

    describe('', () => {
      test('', () => {
        expect(
          'if (if (if true then false else true) then true else false) then false else true'
        ).toEvaluateTo(
          'if (if false then true else false) then false else true'
        );
      });

      test('', () => {
        expect(
          'if (if false then true else false) then false else true'
        ).toEvaluateTo('if false then false else true');
      });

      test('', () => {
        expect('if false then false else true').toEvaluateTo('true');
      });
    });

    expect.extend({
      toFinallyEvaluateTo(before, after) {
        const actual = booleanEvaluation.many(parse(before));
        const expected = parse(after);

        if (actual.equals(expected)) {
          return {
            pass: true,
            message: `expected ${before} not to finally evaluate to “${after}”`
          };
        } else {
          return {
            pass: false,
            message: `expected ${before} to finally evaluate to “${after}”, but got “${actual}”`
          };
        }
      }
    });

    test('', () => {
      expect('if false then false else true').toFinallyEvaluateTo('true');
    });

    test('', () => {
      expect(
        'if (if true then true else false) then false else true'
      ).toFinallyEvaluateTo('false');
    });

    test('', () => {
      expect(
        'if (if (if true then false else true) then true else false) then false else true'
      ).toFinallyEvaluateTo('true');
    });
  });

  const arithmeticTermSyntax = [
    { conclusion: '0 ∈ t' },
    { premises: List.of('_t₁ ∈ t'), conclusion: '(succ _t₁) ∈ t' },
    { premises: List.of('_t₁ ∈ t'), conclusion: '(pred _t₁) ∈ t' },
    { premises: List.of('_t₁ ∈ t'), conclusion: '(iszero _t₁) ∈ t' },

    { conclusion: '0 ∈ nv' },
    { premises: List.of('_nv₁ ∈ nv'), conclusion: '(succ _nv₁) ∈ nv' }
  ];

  const arithmeticSemantics = [
    {
      premises: List.of('_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'),
      conclusion: '(succ _t₁) → (succ _t₁′)'
    },
    { conclusion: '(pred 0) → 0' },
    {
      premises: List.of('_nv₁ ∈ nv'),
      conclusion: '(pred (succ _nv₁)) → _nv₁'
    },
    {
      premises: List.of('_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'),
      conclusion: '(pred _t₁) → (pred _t₁′)'
    },
    { conclusion: '(iszero 0) → true' },
    {
      premises: List.of('_nv₁ ∈ nv'),
      conclusion: '(iszero (succ _nv₁)) → false'
    },
    {
      premises: List.of('_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'),
      conclusion: '(iszero _t₁) → (iszero _t₁′)'
    }
  ];

  describe('arithmetic expressions', () => {
    let arithmeticEvaluation = Relation.define({
      name: '→',
      rules: List.of(
        ...booleanTermSyntax,
        ...booleanSemantics,
        ...arithmeticTermSyntax,
        ...arithmeticSemantics
      )
    });

    expect.extend({
      toFinallyEvaluateTo(before, after) {
        const actual = arithmeticEvaluation.many(parse(before));
        const expected = parse(after);

        if (actual.equals(expected)) {
          return {
            pass: true,
            message: `expected ${before} not to finally evaluate to “${after}”`
          };
        } else {
          return {
            pass: false,
            message: `expected ${before} to finally evaluate to “${after}”, but got “${actual}”`
          };
        }
      }
    });

    test('', () => {
      expect('pred (succ (succ 0))').toFinallyEvaluateTo('succ 0');
    });

    test('', () => {
      expect(
        'if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))'
      ).toFinallyEvaluateTo('0');
    });

    test('', () => {
      expect('pred (succ (succ (pred 0)))').toFinallyEvaluateTo('succ 0');
    });

    test('', () => {
      expect('pred (succ (succ true))').toFinallyEvaluateTo(
        'pred (succ (succ true))'
      );
    });

    test('', () => {
      expect('iszero 0').toFinallyEvaluateTo('true');
    });

    test('', () => {
      expect('iszero (succ 0)').toFinallyEvaluateTo('false');
    });

    test('', () => {
      expect('iszero (succ (succ (succ (succ 0))))').toFinallyEvaluateTo(
        'false'
      );
    });

    test('', () => {
      expect('iszero (succ true)').toFinallyEvaluateTo('iszero (succ true)');
    });
  });
});
