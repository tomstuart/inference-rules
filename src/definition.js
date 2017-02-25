import State from './state';

export default class {
  constructor(rules) {
    this.rules = rules;
  }

  matchRules(expression, state = new State()) {
    return this.rules.map(rule => rule.match(expression, state)).
      filter(match => match !== undefined);
  }

  derive(expression, state = new State()) {
    const states = this.matchRules(expression, state).
      map(match => match.tryPremises(this.derive.bind(this)));

    return Array.prototype.concat.apply([], states).
      filter(state => state !== undefined);
  }
};
