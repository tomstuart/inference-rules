import { keyword, sequence, variable } from './builder_helpers';
import { parse } from './parser_helpers';
import Scope from './scope';

describe('parsing', () => {
  const yes = keyword('true');

  const no = keyword('false');

  const conditional = (condition, consequent, alternative) =>
    sequence(
      keyword('if'),
      condition,
      keyword('then'),
      consequent,
      keyword('else'),
      alternative
    );

  const evaluates = (before, after) => sequence(before, keyword('→'), after);

  describe('without variables', () => {
    test('', () => {
      expect(parse('true')).toEqual(yes);
    });

    test('', () => {
      expect(parse('if false then false else true')).toEqual(
        conditional(no, no, yes)
      );
    });

    test('', () => {
      expect(
        parse('if (if true then true else false) then false else true')
      ).toEqual(conditional(conditional(yes, yes, no), no, yes));
    });
  });

  describe('with variables', () => {
    let scope;

    beforeEach(() => {
      scope = new Scope();
    });

    test('', () => {
      expect(parse('(if true then $t₂ else $t₃) → $t₂', scope)).toEqual(
        evaluates(
          conditional(yes, variable('t₂', scope), variable('t₃', scope)),
          variable('t₂', scope)
        )
      );
    });

    test('', () => {
      expect(parse('(if false then $t₂ else $t₃) → $t₃', scope)).toEqual(
        evaluates(
          conditional(no, variable('t₂', scope), variable('t₃', scope)),
          variable('t₃', scope)
        )
      );
    });

    test('', () => {
      expect(parse('$t₁ → $t₁′', scope)).toEqual(
        evaluates(variable('t₁', scope), variable('t₁′', scope))
      );
    });

    test('', () => {
      expect(
        parse('(if $t₁ then $t₂ else $t₃) → (if $t₁′ then $t₂ else $t₃)', scope)
      ).toEqual(
        evaluates(
          conditional(
            variable('t₁', scope),
            variable('t₂', scope),
            variable('t₃', scope)
          ),
          conditional(
            variable('t₁′', scope),
            variable('t₂', scope),
            variable('t₃', scope)
          )
        )
      );
    });
  });
});
