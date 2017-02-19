require 'ast/sequence'
require 'ast/variable'
require 'ast/word'

class Builder
  def initialize(scope = Object.new)
    self.scope = scope
  end

  def build_sequence(expressions)
    AST::Sequence.new(expressions)
  end

  def build_variable(name)
    AST::Variable.new(name, scope)
  end

  def build_word(name)
    AST::Word.new(name)
  end

  private

  attr_accessor :scope
end
