require 'builder'
require 'parser'
require 'rule'

module RuleHelpers
  def rule(premises, conclusion)
    parser = Parser.new
    builder = Builder.new
    Rule.new(premises.map { |s| parser.parse(s).call(builder) }, parser.parse(conclusion).call(builder))
  end
end
