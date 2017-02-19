require 'parser'
require 'rule'

module RuleHelpers
  def rule(premises, conclusion)
    parser = Parser.new
    premises = premises.map(&parser.method(:parse))
    conclusion = parser.parse(conclusion)

    -> builder { Rule.new(premises.map { |p| p.call(builder) }, conclusion.call(builder)) }
  end
end
