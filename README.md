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
