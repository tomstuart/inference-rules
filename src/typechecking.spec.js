import { Relation, NoRuleApplies } from './relation';
import { parse } from './parser_helpers';
import { List } from 'immutable';

describe('typechecking', () => {
  const booleanTermSyntax = [
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: List.of('_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t'),
      conclusion: '(if _t₁ then _t₂ else _t₃) ∈ t'
    }
  ];

  const booleanTypeSyntax = [{ conclusion: 'Bool ∈ T' }];

  const booleanTypeRules = [
    { conclusion: 'true : Bool' },
    { conclusion: 'false : Bool' },
    {
      premises: List.of(
        '_t₁ : Bool',
        '_t₂ : _T',
        '_t₃ : _T',
        '_t₁ ∈ t',
        '_t₂ ∈ t',
        '_t₃ ∈ t',
        '_T ∈ T'
      ),
      conclusion: '(if _t₁ then _t₂ else _t₃) : _T'
    }
  ];

  describe('boolean expressions', () => {
    const booleanTypechecking = Relation.define({
      name: ':',
      rules: List.of(
        ...booleanTermSyntax,
        ...booleanTypeSyntax,
        ...booleanTypeRules
      )
    });

    expect.extend({
      toTypecheck(term, type) {
        const actualTerm = parse(term);
        const expectedType = type && parse(type);
        let actualType;

        try {
          actualType = booleanTypechecking.once(actualTerm);

          if (!expectedType || actualType.equals(expectedType)) {
            return {
              pass: true,
              message: `expected ${term} not to typecheck as “${type}”`
            };
          }
        } catch (e) {
          if (!e instanceof NoRuleApplies) {
            throw e;
          }
        }

        return {
          pass: false,
          message: `expected ${term} to typecheck as “${type}”, but got “${actualType}”`
        };
      }
    });

    describe('', () => {
      test('', () => {
        expect('true').toTypecheck('Bool');
      });

      test('', () => {
        expect('false').toTypecheck('Bool');
      });

      test('', () => {
        expect('hello').not.toTypecheck();
      });

      test('', () => {
        expect('if false then false else true').toTypecheck('Bool');
      });

      test('', () => {
        expect('if false then hello else true').not.toTypecheck();
      });

      test('', () => {
        expect(
          'if (if (if true then false else true) then true else false) then false else true'
        ).toTypecheck('Bool');
      });
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

  const arithmeticTypeSyntax = [{ conclusion: 'Nat ∈ T' }];

  const arithmeticTypeRules = [
    { conclusion: '0 : Nat' },
    {
      premises: List.of('_t₁ : Nat', '_t₁ ∈ t'),
      conclusion: '(succ _t₁) : Nat'
    },
    {
      premises: List.of('_t₁ : Nat', '_t₁ ∈ t'),
      conclusion: '(pred _t₁) : Nat'
    },
    {
      premises: List.of('_t₁ : Nat', '_t₁ ∈ t'),
      conclusion: '(iszero _t₁) : Bool'
    }
  ];

  describe('arithmetic expressions', () => {
    const arithmeticTypechecking = Relation.define({
      name: ':',
      rules: List.of(
        ...booleanTermSyntax,
        ...booleanTypeSyntax,
        ...booleanTypeRules,
        ...arithmeticTermSyntax,
        ...arithmeticTypeSyntax,
        ...arithmeticTypeRules
      )
    });

    expect.extend({
      toTypecheck(term, type) {
        const actualTerm = parse(term);
        const expectedType = type && parse(type);
        let actualType;

        try {
          actualType = arithmeticTypechecking.once(actualTerm);

          if (!expectedType || actualType.equals(expectedType)) {
            return {
              pass: true,
              message: `expected ${term} not to typecheck as “${type}”`
            };
          }
        } catch (e) {
          if (!e instanceof NoRuleApplies) {
            throw e;
          }
        }

        return {
          pass: false,
          message: `expected ${term} to typecheck as “${type}”, but got “${actualType}”`
        };
      }
    });

    test('', () => {
      expect('pred (succ (succ 0))').toTypecheck('Nat');
    });

    test('', () => {
      expect(
        'if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))'
      ).toTypecheck('Nat');
    });

    test('', () => {
      expect(
        'if (iszero (pred 0)) then (iszero 0) else (iszero (succ 0))'
      ).toTypecheck('Bool');
    });

    test('', () => {
      expect('if (succ 0) then 0 else (succ 0)').not.toTypecheck();
    });

    test('', () => {
      expect('if (iszero 0) then 0 else (iszero 0)').not.toTypecheck();
    });

    test('', () => {
      expect('if (iszero true) then 0 else (succ 0)').not.toTypecheck();
    });
  });
});
