require 'builder'

class Rule
  def initialize(premises, conclusion)
    self.premises, self.conclusion = premises, conclusion
  end

  def to_s
    builder = Builder.new
    premises_string = premises.map { |p| p.call(builder).to_s }.join('  ')
    conclusion_string = conclusion.call(builder).to_s

    [
      (premises_string unless premises_string.empty?),
      '-' * [premises_string, conclusion_string].map(&:length).max,
      conclusion_string
    ].compact.join("\n")
  end

  def match(expression, state)
    builder = Builder.new
    next_state = state.unify(expression, conclusion.call(builder))
    [premises.map { |p| p.call(builder) }, next_state] if next_state
  end

  private

  attr_accessor :premises, :conclusion
end
