import AST from './ast';
import Builder from './builder'
import { Map } from 'immutable';

export default class State {
  constructor(values = Map()) {
    this.values = values;
  }

  assignValue(key, value) {
    return new State(this.values.set(key, value));
  }

  valueOf(key) {
    if (this.values.has(key)) {
      return this.valueOf(this.values.get(key));
    } else if (key instanceof AST.Sequence) {
      return new Builder().buildSequence(key.expressions.map(this.valueOf, this));
    } else {
      return key;
    }
  }

  unify(a, b) {
    const [av, bv] = [a, b].map(this.valueOf, this);

    if (av.equals(bv)) {
      return this;
    } else if (av instanceof AST.Variable) {
      return this.assignValue(av, bv);
    } else if (bv instanceof AST.Variable) {
      return this.assignValue(bv, av);
    } else if (av instanceof AST.Sequence && bv instanceof AST.Sequence) {
      if (av.expressions.size === bv.expressions.size) {
        return av.expressions.zip(bv.expressions).
          reduce((state, [a, b]) => state && state.unify(a, b), this);
      }
    }
  }
};
