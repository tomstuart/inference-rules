import Rule from './rule';
import { List } from 'immutable';

const rule = (premises, conclusion) =>
  Rule.define({ premises: List(premises), conclusion });

export { rule };
