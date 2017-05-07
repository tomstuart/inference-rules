import React, { Component } from 'react';
import Builder from './builder';
import Parser from './parser';
import Relation from './relation';
import Scope from './scope';
import { List } from 'immutable';
import './App.css';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      context: '(f : (Bool → Bool) , ∅)',
      term: 'λ x : Bool . (f (if x then false else x))',
      rules: []
    };

    this.handleContextChange = this.handleContextChange.bind(this);
    this.handleTermChange = this.handleTermChange.bind(this);
  }

  componentDidMount() {
    fetch('rules.json')
      .then(r => r.json())
      .then(rules => { this.setState({ rules }); });
  }

  handleContextChange(event) {
    this.setState({ context: event.target.value });
  }

  handleTermChange(event) {
    this.setState({ term: event.target.value });
  }

  render() {
    const typechecking = Relation.define({
      name: ['⊢', ':'],
      rules: List(this.state.rules.map(rule => ({
        premises: List(rule.premises),
        conclusion: rule.conclusion
      })))
    });

    const parser = new Parser(new Builder(new Scope()));
    let context, term;

    try {
      context = parser.parse(this.state.context);
    } catch (e) {}

    try {
      term = parser.parse(this.state.term);
    } catch (e) {}

    let type = '(no type)';

    if (context && term) {
      try {
        type = typechecking.once(context, term);
      } catch (e) {}
    }

    return (
      <div className="App">
        <form>
          <input size="20" type="text" value={this.state.context} onChange={this.handleContextChange} />
          <span className="relation-symbol">⊢</span>
          <input size="32" type="text" value={this.state.term} onChange={this.handleTermChange} />
          <span className="relation-symbol">:</span>
          <span>{type.toString()}</span>
        </form>
      </div>
    );
  }
}

export default App;
