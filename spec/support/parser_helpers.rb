require 'builder'
require 'parser'

module ParserHelpers
  def parse(string)
    Parser.parse(string).call(Builder.new)
  end
end
