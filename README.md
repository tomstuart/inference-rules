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
to any of its metavariables. If that expression is, for example, `iszero (succ
0) → _t′`, the code could (given the right rules) build a derivation that
assigns `false` to `_t′`.

All of the above is wrapped up in a nice `Relation` class: you give it the name
and rules of the relation, and then you can just ask it to apply the defined
relation `once` (or `many` times) to a particular “input”.

Here’s what it looks like in practice:

```irb
$ irb -Ilib -rparser -rrelation
>> BOOLEAN_SYNTAX =
     { conclusion: 'true ∈ T' },
     { conclusion: 'false ∈ T' },
     {
       premises: ['_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T'],
       conclusion: '(if _t₁ then _t₂ else _t₃) ∈ T'
     }
=> […]

>> BOOLEAN_SEMANTICS =
     {
       premises: ['_t₂ ∈ T', '_t₃ ∈ T'],
       conclusion: '(if true then _t₂ else _t₃) → _t₂'
     },
     {
       premises: ['_t₂ ∈ T', '_t₃ ∈ T'],
       conclusion: '(if false then _t₂ else _t₃) → _t₃'
     },
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₂ ∈ T', '_t₃ ∈ T', '_t₁′ ∈ T'],
       conclusion: '(if _t₁ then _t₂ else _t₃) → (if _t₁′ then _t₂ else _t₃)'
     }
=> […]

>> BOOLEAN_EVALUATION =
     Relation.define \
       name: '→',
       rules: BOOLEAN_SYNTAX + BOOLEAN_SEMANTICS
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

>> ARITHMETIC_SYNTAX =
     { conclusion: '0 ∈ T' },
     { premises: ['_t₁ ∈ T'], conclusion: '(succ _t₁) ∈ T' },
     { premises: ['_t₁ ∈ T'], conclusion: '(pred _t₁) ∈ T' },
     { premises: ['_t₁ ∈ T'], conclusion: '(iszero _t₁) ∈ T' },

     { conclusion: '0 ∈ NV' },
     { premises: ['_nv₁ ∈ NV'], conclusion: '(succ _nv₁) ∈ NV' }
=> […]

>> ARITHMETIC_SEMANTICS =
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'],
       conclusion: '(succ _t₁) → (succ _t₁′)'
     },
     { conclusion: '(pred 0) → 0' },
     {
       premises: ['_nv₁ ∈ NV'],
       conclusion: '(pred (succ _nv₁)) → _nv₁'
     },
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'],
       conclusion: '(pred _t₁) → (pred _t₁′)'
     },
     { conclusion: '(iszero 0) → true' },
     {
       premises: ['_nv₁ ∈ NV'],
       conclusion: '(iszero (succ _nv₁)) → false'
     },
     {
       premises: ['_t₁ → _t₁′', '_t₁ ∈ T', '_t₁′ ∈ T'],
       conclusion: '(iszero _t₁) → (iszero _t₁′)'
     }
=> […]

>> ARITHMETIC_EVALUATION =
     Relation.define \
       name: '→',
       rules: BOOLEAN_SYNTAX + BOOLEAN_SEMANTICS + ARITHMETIC_SYNTAX + ARITHMETIC_SEMANTICS
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
