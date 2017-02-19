require 'ast/builder'

module BuilderHelpers
  def word(name)
    AST::Builder.new.build_word(name)
  end

  def sequence(*expressions)
    AST::Builder.new.build_sequence(expressions)
  end
end
