require 'ast/builder'

module BuilderHelpers
  def sequence(*expressions)
    AST::Builder.new.build_sequence(expressions)
  end

  def variable(name, scope = Object.new)
    AST::Builder.new(scope).build_variable(name)
  end

  def word(name)
    AST::Builder.new.build_word(name)
  end
end
