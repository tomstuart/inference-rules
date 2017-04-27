module AST
  class LazyBuilder
    def build_keyword(name)
      -> builder { builder.build_keyword(name) }
    end

    def build_sequence(expressions)
      -> builder { builder.build_sequence(expressions.map { |e| e.call(builder) }) }
    end

    def build_variable(name)
      -> builder { builder.build_variable(name) }
    end
  end
end
