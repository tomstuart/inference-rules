import Rule from './rule';

const rule = (premises, conclusion) =>
  Rule.define({ premises, conclusion });

export { rule };
