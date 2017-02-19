class Definition
  def initialize(rules)
    self.rules = rules
  end

  def match_rules(expression, state)
    rules.
      select { |rule| rule.matches?(expression, state) }.
      map { |rule| rule.match(expression, state) }
  end

  def derive(expression, state)
    match_rules(expression, state).flat_map { |state, premises|
      premises.inject([state]) { |states, premise|
        states.flat_map { |state| derive(premise, state) }
      }
    }.compact
  end

  private

  attr_accessor :rules
end
