require 'ast/builder'
require 'parser'

module ParserHelpers
  def parse(string, scope = Object.new)
    Parser.new.parse(string).call(AST::Builder.new(scope))
  end
end
