import Builder from './builder';
import Parser from './parser';
import Scope from './scope';

const parse = (string, scope = new Scope()) =>
  new Parser().parse(string)(new Builder(scope));

export { parse };
