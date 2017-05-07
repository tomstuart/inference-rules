require 'ast/expression'

module AST
  class Variable < Struct.new(:name, :scope)
    include Expression

    def to_s
      "$#{name}"
    end

    def find_variable(name)
      self if name == self.name
    end
  end
end
