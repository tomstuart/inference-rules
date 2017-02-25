import AST from './ast';
import Builder from './builder'
import { List, Map } from 'immutable';

export default class State {
  constructor(values = Map()) {
    this.values = values;
  }

  assignValues(moreValues) {
    return new State(this.values.merge(moreValues));
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
    const av = this.valueOf(a), bv = this.valueOf(b);

    if (av.equals(bv)) {
      return this;
    } else if (av instanceof AST.Variable) {
      return this.assignValues(Map([[av, bv]]));
    } else if (bv instanceof AST.Variable) {
      return this.assignValues(Map([[bv, av]]));
    } else if (av instanceof AST.Sequence && bv instanceof AST.Sequence) {
      if (av.expressions.length === bv.expressions.length) {
        return List(av.expressions).zip(bv.expressions).
          reduce((state, [a, b]) => state && state.unify(a, b), this);
      }
    }
  }
};
