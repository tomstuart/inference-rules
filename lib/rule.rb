class Rule
  def initialize(premises, conclusion)
    self.premises, self.conclusion = premises, conclusion
  end

  def to_s
    premises_string = premises.map(&:to_s).join('  ')
    conclusion_string = conclusion.to_s

    [
      (premises_string unless premises_string.empty?),
      '-' * [premises_string, conclusion_string].map(&:length).max,
      conclusion_string
    ].compact.join("\n")
  end

  def match(expression, state)
    next_state = state.unify(expression, conclusion)
    [next_state, premises] if next_state
  end

  def matches?(*args)
    !match(*args).nil?
  end

  private

  attr_accessor :premises, :conclusion
end
