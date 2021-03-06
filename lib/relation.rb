require 'ast/builder'
require 'definition'
require 'rule'

class Relation
  def initialize(name, definition)
    self.name, self.definition = name, definition
  end

  def self.define(name:, rules:)
    new(name, Definition.new(rules.map(&Rule.method(:define))))
  end

  NoRuleApplies = Class.new(StandardError)
  Nondeterministic = Class.new(StandardError)

  def once(*inputs)
    builder = AST::Builder.new
    output = builder.build_variable('output')
    keywords = Array(name).map(&builder.method(:build_keyword))
    formula = builder.build_sequence(inputs.zip(keywords).flatten(1) + [output])
    states = definition.derive(formula)

    raise NoRuleApplies if states.empty?
    raise Nondeterministic, states.map { |s| s.value_of(result) } if states.length > 1

    states.first.value_of(output)
  end

  def many(input)
    begin
      many(once(input))
    rescue NoRuleApplies
      input
    end
  end

  private

  attr_accessor :name, :definition
end
