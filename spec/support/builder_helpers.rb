require 'ast/builder'

module BuilderHelpers
  def keyword(name)
    AST::Builder.new.build_keyword(name)
  end

  def sequence(*expressions)
    AST::Builder.new.build_sequence(expressions)
  end

  def variable(name, scope = Object.new)
    AST::Builder.new(scope).build_variable(name)
  end
end
