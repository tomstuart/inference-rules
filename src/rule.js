import Builder from './builder';
import Parser from './parser';

class Match {
  constructor(premises, state) {
    this.premises = premises;
    this.state = state;
  }

  tryPremises(callback) {
    return this.premises.reduce((states, premise) => {
      const nextStates = states.map(state => callback(premise, state));
      return Array.prototype.concat.apply([], nextStates);
    }, [this.state]);
  }
}

export default class Rule {
  constructor(premises, conclusion) {
    this.premises = premises;
    this.conclusion = conclusion;
  }

  static define({ premises = [], conclusion }) {
    const parser = new Parser();
    return new Rule(premises.map(parser.parse, parser), parser.parse(conclusion));
  }

  match(expression, state) {
    const builder = new Builder();
    const nextState = state.unify(expression, this.conclusion(builder));

    if (nextState !== undefined) {
      return new Match(this.premises.map(p => p(builder)), nextState);
    }
  }
};
