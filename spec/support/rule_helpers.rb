require 'parser'
require 'rule'

module RuleHelpers
  def rule(premises, conclusion)
    parser = Parser.new
    Rule.new(premises.map(&parser.method(:parse)), parser.parse(conclusion))
  end
end
