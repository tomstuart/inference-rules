require 'formula'
require 'variable'

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

  def build_symbol(name)
    name.to_sym
  end

  private

  attr_accessor :scope
end
