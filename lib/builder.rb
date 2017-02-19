require 'formula'
require 'variable'

class Builder
  def initialize(scope = Object.new)
    self.scope = scope
  end

  def build_true
    :true
  end

  def build_false
    :false
  end

  def build_conditional(condition, consequent, alternative)
    Formula.new([:if, condition, :then, consequent, :else, alternative])
  end

  def build_zero
    :'0'
  end

  def build_succ(term)
    Formula.new([:succ, term])
  end

  def build_pred(term)
    Formula.new([:pred, term])
  end

  def build_iszero(term)
    Formula.new([:iszero, term])
  end

  def build_evaluates(before, after)
    Formula.new([before, :→, after])
  end

  def build_element_of(element, set)
    Formula.new([element, :∈, set])
  end

  def build_constant(name)
    name
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
