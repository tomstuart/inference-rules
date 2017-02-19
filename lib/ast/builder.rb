require 'ast/sequence'
require 'ast/variable'
require 'ast/word'

module AST
  class Builder
    def initialize(scope = Object.new)
      self.scope = scope
    end

    def build_sequence(expressions)
      Sequence.new(expressions)
    end

    def build_variable(name)
      Variable.new(name, scope)
    end

    def build_word(name)
      Word.new(name)
    end

    private

    attr_accessor :scope
  end
end
