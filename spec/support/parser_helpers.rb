require 'parser'

module ParserHelpers
  def parse(string)
    Parser.parse(string)
  end
end
