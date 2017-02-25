import { Record } from 'immutable';

const KEYWORD = {}, SEQUENCE = {}, VARIABLE = {};

export default {
  Keyword: class extends Record({ type: KEYWORD, name: undefined }) {},
  Sequence: class extends Record({ type: SEQUENCE, expressions: undefined }) {},
  Variable: class extends Record({ type: VARIABLE, name: undefined, scope: undefined }) {}
};
