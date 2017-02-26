import AST from './ast';
import { List } from 'immutable';
import Scope from './scope';

export default class {
  constructor(scope = new Scope()) {
    this.scope = scope;
  }

  buildKeyword(name) {
    return new AST.Keyword({ name });
  }

  buildSequence(expressions) {
    return new AST.Sequence({ expressions: List(expressions) });
  }

  buildVariable(name) {
    return new AST.Variable({ name, scope: this.scope });
  }
};
