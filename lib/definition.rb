require 'state'

class Definition
  def initialize(rules)
    self.rules = rules
  end

  def match_rules(expression, state = State.new)
    rules.map { |rule| rule.match(expression, state) }.compact
  end

  def derive(expression, state = State.new)
    match_rules(expression, state).
      flat_map { |match| match.try_premises(&method(:derive)) }.
      compact
  end

  private

  attr_accessor :rules
end
