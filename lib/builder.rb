require 'sequence'
require 'variable'
require 'word'

class Builder
  def initialize(scope = Object.new)
    self.scope = scope
  end

  def build_sequence(expressions)
    Sequence.new(expressions)
  end

  def build_variable(name)
    Variable.new(name, scope)
  end

  def build_word(name)
    Word.new(name)
  end

  private

  attr_accessor :scope
end
