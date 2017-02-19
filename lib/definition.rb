require 'state'

class Definition
  def initialize(rules)
    self.rules = rules
  end

  def match_rules(expression, state = State.new)
    rules.map { |rule| rule.match(expression, state) }.compact
  end

  def derive(expression, state = State.new)
    match_rules(expression, state).flat_map { |match|
      match.premises.inject([match.state]) { |states, premise|
        states.flat_map { |state| derive(premise, state) }
      }
    }.compact
  end

  private

  attr_accessor :rules
end
