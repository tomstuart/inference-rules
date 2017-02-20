require 'rule'

module RuleHelpers
  def rule(premises, conclusion)
    Rule.define(premises: premises, conclusion: conclusion)
  end
end
