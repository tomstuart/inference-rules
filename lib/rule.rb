class Rule
  def initialize(premises, conclusion)
    @premises, @conclusion = premises, conclusion
  end

  attr_reader :premises, :conclusion

  def to_s
    premises_string = premises.map(&:to_s).join('  ')
    conclusion_string = conclusion.to_s

    [
      (premises_string unless premises_string.empty?),
      '-' * [premises_string, conclusion_string].map(&:length).max,
      conclusion_string
    ].compact.join("\n")
  end

  def match(formula, state)
    state.unify(formula, conclusion)
  end

  def matches?(*args)
    !match(*args).nil?
  end
end
