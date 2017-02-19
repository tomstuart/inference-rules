require 'ast/builder'
require 'parser'

module ParserHelpers
  def parse(string)
    Parser.parse(string).call(AST::Builder.new)
  end
end
