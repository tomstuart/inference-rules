import Builder from './builder';
import Scope from './scope';

const keyword = name => new Builder().buildKeyword(name);

const sequence = (...expressions) => new Builder().buildSequence(expressions);

const variable = (name, scope = new Scope()) =>
  new Builder(scope).buildVariable(name);

export { keyword, sequence, variable };
