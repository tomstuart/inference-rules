import { Relation, NoRuleApplies } from './relation';
import { parse } from './parser_helpers';
import { List } from 'immutable';

describe('typechecking', () => {
  const booleanTermSyntax = [
    { conclusion: 'true ∈ t' },
    { conclusion: 'false ∈ t' },
    {
      premises: List.of('$t₁ ∈ t', '$t₂ ∈ t', '$t₃ ∈ t'),
      conclusion: '(if $t₁ then $t₂ else $t₃) ∈ t'
    }
  ];

  const booleanTypeSyntax = [{ conclusion: 'Bool ∈ T' }];

  const booleanTypeRules = [
    { conclusion: 'true : Bool' },
    { conclusion: 'false : Bool' },
    {
      premises: List.of(
        '$t₁ : Bool',
        '$t₂ : $T',
        '$t₃ : $T',
        '$t₁ ∈ t',
        '$t₂ ∈ t',
        '$t₃ ∈ t',
        '$T ∈ T'
      ),
      conclusion: '(if $t₁ then $t₂ else $t₃) : $T'
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
    { premises: List.of('$t₁ ∈ t'), conclusion: '(succ $t₁) ∈ t' },
    { premises: List.of('$t₁ ∈ t'), conclusion: '(pred $t₁) ∈ t' },
    { premises: List.of('$t₁ ∈ t'), conclusion: '(iszero $t₁) ∈ t' },

    { conclusion: '0 ∈ nv' },
    { premises: List.of('$nv₁ ∈ nv'), conclusion: '(succ $nv₁) ∈ nv' }
  ];

  const arithmeticTypeSyntax = [{ conclusion: 'Nat ∈ T' }];

  const arithmeticTypeRules = [
    { conclusion: '0 : Nat' },
    {
      premises: List.of('$t₁ : Nat', '$t₁ ∈ t'),
      conclusion: '(succ $t₁) : Nat'
    },
    {
      premises: List.of('$t₁ : Nat', '$t₁ ∈ t'),
      conclusion: '(pred $t₁) : Nat'
    },
    {
      premises: List.of('$t₁ : Nat', '$t₁ ∈ t'),
      conclusion: '(iszero $t₁) : Bool'
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
      premises: List.of('$x ∈ x'),
      conclusion: '$x ∈ t'
    },
    {
      premises: List.of('$x ∈ x', '$T ∈ T', '$t ∈ t'),
      conclusion: '(λ $x : $T . $t) ∈ t'
    },
    {
      premises: List.of('$t₁ ∈ t', '$t₂ ∈ t'),
      conclusion: '($t₁ $t₂) ∈ t'
    }
  ];

  const lambdaCalculusTypeSyntax = [
    {
      premises: List.of('$T₁ ∈ T', '$T₂ ∈ T'),
      conclusion: '($T₁ → $T₂) ∈ T'
    }
  ];

  const lambdaCalculusTypingContextRules = [
    { conclusion: '∅ ∈ Г' },
    {
      premises: List.of('$x ∈ x', '$T ∈ T', '$Г ∈ Г'),
      conclusion: '($x : $T , $Г) ∈ Г'
    },
    {
      premises: List.of('$x ∈ x', '$T ∈ T', '$Г ∈ Г'),
      conclusion: '($x : $T , $Г) assumes ($x : $T)'
    },
    {
      premises: List.of(
        '$Г assumes ($x₂ : $T₂)',
        '$x₁ ∈ x',
        '$x₂ ∈ x',
        '$T₁ ∈ T',
        '$T₂ ∈ T',
        '$Г ∈ Г'
      ),
      conclusion: '($x₁ : $T₁ , $Г) assumes ($x₂ : $T₂)'
    }
  ];

  const lambdaCalculusTypeRules = [
    {
      premises: List.of('$Г ∈ Г'),
      conclusion: '$Г ⊢ true : Bool'
    },
    {
      premises: List.of('$Г ∈ Г'),
      conclusion: '$Г ⊢ false : Bool'
    },
    {
      premises: List.of(
        '$Г ⊢ $t₁ : Bool',
        '$Г ⊢ $t₂ : $T',
        '$Г ⊢ $t₃ : $T',
        '$Г ∈ Г',
        '$t₁ ∈ t',
        '$t₂ ∈ t',
        '$t₃ ∈ t',
        '$T ∈ T'
      ),
      conclusion: '$Г ⊢ (if $t₁ then $t₂ else $t₃) : $T'
    },
    {
      premises: List.of('$Г assumes ($x : $T)', '$x ∈ x', '$T ∈ T', '$Г ∈ Г'),
      conclusion: '$Г ⊢ $x : $T'
    },
    {
      premises: List.of(
        '($x : $T₁ , $Г) ⊢ $t₂ : $T₂',
        '$Г ∈ Г',
        '$x ∈ x',
        '$T₁ ∈ T',
        '$t₂ ∈ t',
        '$T₂ ∈ T'
      ),
      conclusion: '$Г ⊢ (λ $x : $T₁ . $t₂) : ($T₁ → $T₂)'
    },
    {
      premises: List.of(
        '$Г ⊢ $t₁ : ($T₁₁ → $T₁₂)',
        '$Г ⊢ $t₂ : $T₁₁',
        '$Г ∈ Г',
        '$t₁ ∈ t',
        '$T₁₁ ∈ T',
        '$T₁₂ ∈ T',
        '$t₂ ∈ t'
      ),
      conclusion: '$Г ⊢ ($t₁ $t₂) : $T₁₂'
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
