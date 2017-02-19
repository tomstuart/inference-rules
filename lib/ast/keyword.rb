require 'ast/expression'

module AST
  class Keyword < Struct.new(:name)
    include Expression

    def to_s
      name
    end

    def find_variable(name)
      nil
    end
  end
end
