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
      toArithmeticTypecheck(term, type) {
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
      expect('pred (succ (succ 0))').toArithmeticTypecheck('Nat');
    });

    test('', () => {
      expect(
        'if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))'
      ).toArithmeticTypecheck('Nat');
    });

    test('', () => {
      expect(
        'if (iszero (pred 0)) then (iszero 0) else (iszero (succ 0))'
      ).toArithmeticTypecheck('Bool');
    });

    test('', () => {
      expect('if (succ 0) then 0 else (succ 0)').not.toArithmeticTypecheck();
    });

    test('', () => {
      expect(
        'if (iszero 0) then 0 else (iszero 0)'
      ).not.toArithmeticTypecheck();
    });

    test('', () => {
      expect(
        'if (iszero true) then 0 else (succ 0)'
      ).not.toArithmeticTypecheck();
    });
  });

  const lambdaCalculusTermSyntax = [
    { conclusion: 'a ∈ x' },
    { conclusion: 'b ∈ x' },
    { conclusion: 'c ∈ x' },
    { conclusion: 'd ∈ x' },
    { conclusion: 'e ∈ x' },
    { conclusion: 'f ∈ x' },
    { conclusion: 'g ∈ x' },
    { conclusion: 'x ∈ x' },
    { conclusion: 'y ∈ x' },
    { conclusion: 'z ∈ x' },
    {
      premises: List.of('_x ∈ x'),
      conclusion: '_x ∈ t'
    },
    {
      premises: List.of('_x ∈ x', '_T ∈ T', '_t ∈ t'),
      conclusion: '(λ _x : _T . _t) ∈ t'
    },
    {
      premises: List.of('_t₁ ∈ t', '_t₂ ∈ t'),
      conclusion: '(_t₁ _t₂) ∈ t'
    }
  ];

  const lambdaCalculusTypeSyntax = [
    {
      premises: List.of('_T₁ ∈ T', '_T₂ ∈ T'),
      conclusion: '(_T₁ → _T₂) ∈ T'
    }
  ];

  const lambdaCalculusTypingContextRules = [
    { conclusion: '∅ ∈ Г' },
    {
      premises: List.of('_x ∈ x', '_T ∈ T', '_Г ∈ Г'),
      conclusion: '(_x : _T , _Г) ∈ Г'
    },
    {
      premises: List.of('_x ∈ x', '_T ∈ T', '_Г ∈ Г'),
      conclusion: '(_x : _T , _Г) assumes (_x : _T)'
    },
    {
      premises: List.of(
        '_Г assumes (_x₂ : _T₂)',
        '_x₁ ∈ x',
        '_x₂ ∈ x',
        '_T₁ ∈ T',
        '_T₂ ∈ T',
        '_Г ∈ Г'
      ),
      conclusion: '(_x₁ : _T₁ , _Г) assumes (_x₂ : _T₂)'
    }
  ];

  const lambdaCalculusTypeRules = [
    {
      premises: List.of('_Г ∈ Г'),
      conclusion: '_Г ⊢ true : Bool'
    },
    {
      premises: List.of('_Г ∈ Г'),
      conclusion: '_Г ⊢ false : Bool'
    },
    {
      premises: List.of(
        '_Г ⊢ _t₁ : Bool',
        '_Г ⊢ _t₂ : _T',
        '_Г ⊢ _t₃ : _T',
        '_Г ∈ Г',
        '_t₁ ∈ t',
        '_t₂ ∈ t',
        '_t₃ ∈ t',
        '_T ∈ T'
      ),
      conclusion: '_Г ⊢ (if _t₁ then _t₂ else _t₃) : _T'
    },
    {
      premises: List.of('_Г assumes (_x : _T)', '_x ∈ x', '_T ∈ T', '_Г ∈ Г'),
      conclusion: '_Г ⊢ _x : _T'
    },
    {
      premises: List.of(
        '(_x : _T₁ , _Г) ⊢ _t₂ : _T₂',
        '_Г ∈ Г',
        '_x ∈ x',
        '_T₁ ∈ T',
        '_t₂ ∈ t',
        '_T₂ ∈ T'
      ),
      conclusion: '_Г ⊢ (λ _x : _T₁ . _t₂) : (_T₁ → _T₂)'
    },
    {
      premises: List.of(
        '_Г ⊢ _t₁ : (_T₁₁ → _T₁₂)',
        '_Г ⊢ _t₂ : _T₁₁',
        '_Г ∈ Г',
        '_t₁ ∈ t',
        '_T₁₁ ∈ T',
        '_T₁₂ ∈ T',
        '_t₂ ∈ t'
      ),
      conclusion: '_Г ⊢ (_t₁ _t₂) : _T₁₂'
    }
  ];

  describe('lambda calculus expressions', () => {
    const lambdaCalculusTypechecking = Relation.define({
      name: ['⊢', ':'],
      rules: List.of(
        ...booleanTermSyntax,
        ...lambdaCalculusTermSyntax,
        ...booleanTypeSyntax,
        ...lambdaCalculusTypeSyntax,
        ...lambdaCalculusTypingContextRules,
        ...lambdaCalculusTypeRules
      )
    });

    expect.extend({
      toTypecheck(term, type, context) {
        const actualContext = parse(context || '∅');
        const actualTerm = parse(term);
        const expectedType = type && parse(type);
        let actualType;

        try {
          actualType = lambdaCalculusTypechecking.once(
            actualContext,
            actualTerm
          );

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
        expect('a').toTypecheck('Bool', '(a : Bool , ∅)');
      });
      test('', () => {
        expect('λ a : Bool . a').toTypecheck('Bool → Bool');
      });
      test('', () => {
        expect('a true').toTypecheck('Bool', '(a : (Bool → Bool) , ∅)');
      });

      test('', () => {
        expect('(λ a : Bool . a) true').toTypecheck('Bool');
      });
      test('', () => {
        expect('(λ a : (Bool → Bool) . a) (λ b : Bool . b)').toTypecheck(
          'Bool → Bool'
        );
      });
      test('', () => {
        expect('(λ a : Bool . a) (λ b : Bool . b)').not.toTypecheck();
      });

      test('', () => {
        expect('f (if false then true else false)').not.toTypecheck();
      });
      test('', () => {
        expect('f (if false then true else false)').toTypecheck(
          'Bool',
          '(f : (Bool → Bool) , ∅)'
        );
      });

      test('', () => {
        expect('λ x : Bool . (f (if x then false else x))').not.toTypecheck();
      });
      test('', () => {
        expect('λ x : Bool . (f (if x then false else x))').toTypecheck(
          'Bool → Bool',
          '(f : (Bool → Bool) , ∅)'
        );
      });
    });
  });
});
