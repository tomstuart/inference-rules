export default class {
  constructor(builder) {
    this.builder = builder;
  }

  parse(string) {
    this.string = string;
    return this.parseEverything();
  }

  get string() {
    return this._string;
  }

  set string(string) {
    this._string = string.trim();
  }

  parseEverything() {
    const expression = this.parseSequence();
    this.read(/$/);

    return expression;
  }

  parseSequence() {
    const expressions = [];

    while (!this.canRead(/\)|$/)) {
      expressions.push(this.parseExpression());
    }

    if (expressions.length === 1) {
      return expressions[0];
    } else {
      return this.builder.buildSequence(expressions);
    }
  }

  parseExpression() {
    if (this.canRead(/\(/)) {
      return this.parseBrackets();
    } else if (this.canRead(/_/)) {
      return this.parseVariable();
    } else if (this.canRead(/[^\s()]+/)) {
      return this.parseKeyword();
    } else {
      this.complain();
    }
  }

  parseBrackets() {
    this.read(/\(/);
    const expression = this.parseSequence();
    this.read(/\)/);

    return expression;
  }

  parseVariable() {
    this.read(/_/);
    return this.builder.buildVariable(this.readName());
  }

  parseKeyword() {
    return this.builder.buildKeyword(this.readName());
  }

  readName() {
    return this.read(/[^\s()]+/);
  }

  canRead(pattern) {
    return this.tryMatch(pattern) !== null;
  }

  read(pattern) {
    const match = this.tryMatch(pattern);
    if (match === null) {
      this.complain(pattern);
    }

    this.string = match[2];

    return match[1];
  }

  tryMatch(pattern) {
    return this.string.match(new RegExp('^(' + pattern.source + ')(.*)$'));
  }

  complain(expected) {
    let complaint = 'unexpected ';

    if (this.string.length === 0) {
      complaint += 'end of string';
    } else {
      complaint += '"' + this.string.charAt(0) + '"';
    }

    if (expected !== undefined) {
      complaint += ', expected ' + expected;
    }

    throw new Error(complaint);
  }
}
