import Builder from './builder';
import Definition from './definition';
import Rule from './rule';

class NoRuleApplies extends Error {
  constructor(message) {
    super(message);
    this.name = 'NoRuleApplies';
  }
}

class Nondeterministic extends Error {
  constructor(message) {
    super(message);
    this.name = 'Nondeterministic';
  }
}

export default class Relation {
  constructor(name, definition) {
    this.name = name;
    this.definition = definition;
  }

  static define({ name, rules }) {
    return new Relation(name, new Definition(rules.map(Rule.define)));
  }

  once(input) {
    const builder = new Builder();
    const output = builder.buildVariable('output');
    const formula = builder.buildSequence([
      input,
      builder.buildKeyword(this.name),
      output
    ]);
    const states = this.definition.derive(formula);

    if (states.isEmpty()) {
      throw new NoRuleApplies();
    }

    if (states.size > 1) {
      throw new Nondeterministic();
    }

    return states.first().valueOf(output);
  }

  many(input) {
    try {
      return this.many(this.once(input));
    } catch (e) {
      if (e instanceof NoRuleApplies) {
        return input;
      } else {
        throw e;
      }
    }
  }
}

export { NoRuleApplies, Nondeterministic, Relation };
