require 'ast/builder'

class Evaluator
  def initialize(definition, keyword)
    self.definition, self.keyword = definition, keyword
    self.builder = AST::Builder.new
  end

  NoRuleApplies = Class.new(StandardError)
  Nondeterministic = Class.new(StandardError)

  def eval1(term)
    result = builder.build_variable('result')
    formula = builder.build_sequence([term, keyword, result])
    states = definition.derive(formula)

    raise NoRuleApplies if states.empty?
    raise Nondeterministic, states.map { |s| s.value_of(result) } if states.length > 1

    states.first.value_of(result)
  end

  def evaluate(term)
    begin
      evaluate(eval1(term))
    rescue NoRuleApplies
      term
    end
  end

  private

  attr_accessor :definition, :keyword, :builder
end
