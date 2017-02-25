import { Record } from 'immutable';

const KEYWORD = {}, SEQUENCE = {}, VARIABLE = {};

export default {
  Keyword: class extends Record({ type: KEYWORD, name: undefined }) {
    toString() {
      return this.name;
    }

    bracketed() {
      return this.toString();
    }

    findVariable(name) {}
  },

  Sequence: class extends Record({ type: SEQUENCE, expressions: undefined }) {
    toString() {
      return this.expressions.map(e => e.bracketed()).join(' ');
    }

    bracketed() {
      return `(${this})`
    }

    findVariable(name) {
      for (let i = 0; i < this.expressions.length; ++i) {
        const expression = this.expressions[i];
        const result = expression.findVariable(name);

        if (result !== undefined) {
          return result;
        }
      }
    }
  },

  Variable: class extends Record({ type: VARIABLE, name: undefined, scope: undefined }) {
    toString() {
      return `_${this.name}`;
    }

    bracketed() {
      return this.toString();
    }

    findVariable(name) {
      if (name === this.name) {
        return this;
      }
    }
  }
};
