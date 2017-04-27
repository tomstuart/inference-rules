require 'ast/builder'
require 'parser'

module ParserHelpers
  def parse(string, scope = Object.new)
    Parser.new(AST::Builder.new(scope)).parse(string)
  end
end
