export default {
  Keyword: class {
    constructor(name) {
      this.name = name;
    }
  },

  Sequence: class {
    constructor(expressions) {
      this.expressions = expressions;
    }
  },

  Variable: class {
    constructor(name, scope) {
      this.name = name;
      this.scope = scope;
    }
  }
};
