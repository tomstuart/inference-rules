require 'formula'
require 'variable'
require 'word'

class Builder
  def initialize(scope = Object.new)
    self.scope = scope
  end

  def build_formula(parts)
    Formula.new(parts)
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
