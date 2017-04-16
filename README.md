# Inference rules

This is an attempt at an implementation of [inference
rules](https://en.wikipedia.org/wiki/Rule_of_inference), specifically for the
purpose of being able to evaluate the languages in Chapter 3 of [Types and
Programming Languages](https://www.cis.upenn.edu/~bcpierce/tapl/).

The approach is to write the premises and conclusion of each inference rule in
a simple, generic [metalanguage](https://en.wikipedia.org/wiki/Metalanguage):

* anything that starts with an underscore is a metavariable;
* anything in brackets is a nested expression; and
* anything else is a (whitespace-delimited) keyword.

This doesn’t assume anything in particular about the [object
language](https://en.wikipedia.org/wiki/Object_language) that the rules are
describing, except that it’s whitespace-delimited and brackets are its only
nesting construct, which are probably acceptable constraints for a toy
language.

For example: the language of boolean expressions from TAPL Chapter 3 has terms
like `if … then … else …`, but our metalanguage doesn’t care about that
structure — it just recognises that `if`, `then` and `else` are keywords. The
downside is that if we want to write a nested boolean expression we have to say
`if (if … then … else …) then … else …` so that the parser knows where the
nesting happens.

Likewise the relation symbols in the rules (e.g. `∈` and `→`, for syntactic
validity and single-step evaluation respectively) don’t have any meaning beyond
just being non-ASCII keywords in the notional language of formulae.

The code in this repository does the work of parsing this syntax and
recursively building derivations of the resulting rules. The upshot is that you
can write a bunch of rules describing some language and then apply those rules
to some expression in that language to see if the derivation can assign values
to any of its metavariables. If that expression is, for example, `(iszero (succ
0)) → _t′`, the code could (given the right rules) build a derivation that
assigns `false` to `_t′`.

All of the above is wrapped up in a nice `Relation` class: you give it the name
and rules of the relation, and then you can just ask it to apply the defined
relation `once` (or `many` times) to a particular “input”. Concretely, that
means that if you make a `Relation` called “`→`” and ask for it to be applied
to the input `iszero (succ 0)`, it will build the expression `(iszero (succ 0))
→ _output` for you, build a derivation of that expression using the inference
rules you provided, and then return the value that the derivation assigned to
the `_output` metavariable.

## Example: small-step evaluation

Here’s what it looks like in practice:

```irb
$ irb -Ilib -rparser -rrelation
>> BOOLEAN_TERM_SYNTAX =
     { conclusion: 'true ∈ t' },
     { conclusion: 'false ∈ t' },
     {
       premises: ['_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t'],
       conclusion: '(if _t₁ then _t₂ else _t₃) ∈ t'
     }
=> […]

>> BOOLEAN_SEMANTICS =
     {
       premises: ['_t₂ ∈ t', '_t₃ ∈ t'],
       conclusion: '(if true then _t₂ else _t₃) → _t₂'
     },
     {
       premises: ['_t₂ ∈ t', '_t₃ ∈ t'],
       conclusion: '(if false then _t₂ else _t₃) → _t₃'
     },
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t', '_t₁′ ∈ t'],
       conclusion: '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)'
     }
=> […]

>> BOOLEAN_EVALUATION =
     Relation.define \
       name: '→',
       rules: BOOLEAN_TERM_SYNTAX + BOOLEAN_SEMANTICS
=> #<Relation @name="→", @definition=#<Definition @rules=[…]>>

>> def eval1(term)
     BOOLEAN_EVALUATION.once(term)
   end
=> :eval1

>> def evaluate(term)
     BOOLEAN_EVALUATION.many(term)
   end
=> :evaluate

>> term = Parser.parse 'if (if false then true else (if true then true else false)) then false else true'
=> «if (if false then true else (if true then true else false)) then false else true»

>> eval1(term)
=> «if (if true then true else false) then false else true»
>> eval1(_)
=> «if true then false else true»
>> eval1(_)
=> «false»

>> evaluate(term)
=> «false»

>> ARITHMETIC_TERM_SYNTAX =
     { conclusion: '0 ∈ t' },
     { premises: ['_t₁ ∈ t'], conclusion: '(succ _t₁) ∈ t' },
     { premises: ['_t₁ ∈ t'], conclusion: '(pred _t₁) ∈ t' },
     { premises: ['_t₁ ∈ t'], conclusion: '(iszero _t₁) ∈ t' },

     { conclusion: '0 ∈ nv' },
     { premises: ['_nv₁ ∈ nv'], conclusion: '(succ _nv₁) ∈ nv' }
=> […]

>> ARITHMETIC_SEMANTICS =
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'],
       conclusion: '(succ _t₁) → (succ _t₁′)'
     },
     { conclusion: '(pred 0) → 0' },
     {
       premises: ['_nv₁ ∈ nv'],
       conclusion: '(pred (succ _nv₁)) → _nv₁'
     },
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'],
       conclusion: '(pred _t₁) → (pred _t₁′)'
     },
     { conclusion: '(iszero 0) → true' },
     {
       premises: ['_nv₁ ∈ nv'],
       conclusion: '(iszero (succ _nv₁)) → false'
     },
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ t', '_t₁′ ∈ t'],
       conclusion: '(iszero _t₁) → (iszero _t₁′)'
     }
=> […]

>> ARITHMETIC_EVALUATION =
     Relation.define \
       name: '→',
       rules: BOOLEAN_TERM_SYNTAX + BOOLEAN_SEMANTICS + ARITHMETIC_TERM_SYNTAX + ARITHMETIC_SEMANTICS
=> #<Relation @name="→", @definition=#<Definition @rules=[…]>>

>> def eval1(term)
     ARITHMETIC_EVALUATION.once(term)
   end
=> :eval1

>> def evaluate(term)
     ARITHMETIC_EVALUATION.many(term)
   end
=> :evaluate

>> term = Parser.parse 'if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))'
=> «if (iszero (succ 0)) then (succ (pred 0)) else (pred (succ 0))»

>> eval1(term)
=> «if false then (succ (pred 0)) else (pred (succ 0))»
>> eval1(_)
=> «pred (succ 0)»
>> eval1(_)
=> «0»

>> evaluate(term)
=> «0»
```

Note that the metalanguage places no implicit syntactic constraints on
metavariables — as far as the system is concerned, a metavariable called `_nv₁`
can have any value whatsoever as long as all premises are satisfied. In the
above semantics, important syntactic constraints (`_t₁ ∈ t` and `_nv₁ ∈ nv`)
are defined with extra inference rules and expressed explicitly with extra
premises on the semantic rules.

## Example: typechecking

Because the metalanguage is agnostic about the meaning of relations, we can
define a typechecker instead of an evaluator just by writing different rules:

```irb
>> BOOLEAN_TYPE_SYNTAX = [
     { conclusion: 'Bool ∈ T' }
   ]
=> […]

>> BOOLEAN_TYPE_RULES =
     { conclusion: 'true : Bool' },
     { conclusion: 'false : Bool' },
     {
       premises: ['_t₁ : Bool', '_t₂ : _T', '_t₃ : _T', '_t₁ ∈ t', '_t₂ ∈ t', '_t₃ ∈ t', '_T ∈ T'],
       conclusion: '(if _t₁ then _t₂ else _t₃) : _T'
     }
=> […]

>> BOOLEAN_TYPECHECKING =
     Relation.define \
       name: ':',
       rules: BOOLEAN_TERM_SYNTAX + BOOLEAN_TYPE_SYNTAX + BOOLEAN_TYPE_RULES
=> #<Relation @name=":", @definition=#<Definition @rules=[…]>>

>> def type_of(term)
     begin
       BOOLEAN_TYPECHECKING.once(term)
     rescue Relation::NoRuleApplies
       nil
     end
   end
=> :type_of

>> type_of(Parser.parse('if (if false then true else (if true then true else false)) then false else true'))
=> «Bool»

> type_of(Parser.parse('hello world'))
=> nil

>> ARITHMETIC_TYPE_SYNTAX = [
     { conclusion: 'Nat ∈ T' }
   ]
=> […]

>> ARITHMETIC_TYPE_RULES =
     { conclusion: '0 : Nat' },
     {
       premises: ['_t₁ : Nat', '_t₁ ∈ t'],
       conclusion: '(succ _t₁) : Nat'
     },
     {
       premises: ['_t₁ : Nat', '_t₁ ∈ t'],
       conclusion: '(pred _t₁) : Nat'
     },
     {
       premises: ['_t₁ : Nat', '_t₁ ∈ t'],
       conclusion: '(iszero _t₁) : Bool'
     }

>> ARITHMETIC_TYPECHECKING =
     Relation.define \
       name: ':',
       rules: BOOLEAN_TERM_SYNTAX + BOOLEAN_TYPE_SYNTAX + BOOLEAN_TYPE_RULES +
              ARITHMETIC_TERM_SYNTAX + ARITHMETIC_TYPE_SYNTAX + ARITHMETIC_TYPE_RULES
=> #<Relation @name=":", @definition=#<Definition @rules=[…]>>

>> def type_of(term)
     begin
       ARITHMETIC_TYPECHECKING.once(term)
     rescue Relation::NoRuleApplies
       nil
     end
   end
=> :type_of

>> type_of(Parser.parse('if (iszero 0) then (succ 0) else 0'))
=> «Nat»

>> type_of(Parser.parse('if (iszero (succ 0)) then (iszero 0) else (iszero (pred 0))'))
=> «Bool»

>> type_of(Parser.parse('if (succ 0) then true else false'))
=> nil

>> type_of(Parser.parse('if true then (succ 0) else (iszero 0)'))
=> nil
```
