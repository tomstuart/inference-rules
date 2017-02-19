class State
  def initialize(values = {})
    @values = values
  end

  attr_reader :values

  def assign_values(more_values)
    self.class.new(values.merge(more_values) { |key| raise key })
  end

  def value_of(key)
    if values.has_key?(key)
      value_of values.fetch(key)
    elsif key.is_a?(Sequence)
      Sequence.new(key.expressions.map(&method(:value_of)))
    else
      key
    end
  end

  def unify(a, b)
    a, b = value_of(a), value_of(b)

    if a == b
      self
    elsif a.is_a?(Variable)
      assign_values a => b
    elsif b.is_a?(Variable)
      assign_values b => a
    elsif a.is_a?(Sequence) && b.is_a?(Sequence)
      if a.expressions.length == b.expressions.length
        [a, b].map(&:expressions).transpose.inject(self) do |state, (a, b)|
          state && state.unify(a, b)
        end
      end
    end
  end
end
