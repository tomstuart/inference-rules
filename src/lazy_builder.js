export default class {
  buildKeyword(name) {
    return builder => builder.buildKeyword(name);
  }

  buildSequence(expressions) {
    return builder => builder.buildSequence(expressions.map(e => e(builder)));
  }

  buildVariable(name) {
    return builder => builder.buildVariable(name);
  }
}
