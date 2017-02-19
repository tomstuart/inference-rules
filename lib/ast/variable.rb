require 'ast/expression'

module AST
  class Variable < Struct.new(:name, :scope)
    include Expression

    def to_s
      "_#{name}"
    end

    def find_variable(name)
      if self.name == name
        self
      else
        nil
      end
    end
  end
end
