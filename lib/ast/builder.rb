require 'ast/keyword'
require 'ast/sequence'
require 'ast/variable'

module AST
  class Builder
    def initialize(scope = Object.new)
      self.scope = scope
    end

    def build_keyword(name)
      Keyword.new(name)
    end

    def build_sequence(expressions)
      Sequence.new(expressions)
    end

    def build_variable(name)
      Variable.new(name, scope)
    end

    private

    attr_accessor :scope
  end
end
