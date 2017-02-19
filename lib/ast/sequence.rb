require 'ast/expression'

module AST
  class Sequence < Struct.new(:expressions)
    include Expression

    def to_s
      expressions.map(&:bracketed).join(' ')
    end

    def bracketed
      "(#{to_s})"
    end

    def find_variable(name)
      expressions.each do |expression|
        result = expression.find_variable(name)
        return result if result
      end

      nil
    end
  end
end
