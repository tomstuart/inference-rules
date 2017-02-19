require 'builder'

module BuilderHelpers
  def word(name)
    Builder.new.build_word(name)
  end

  def sequence(*expressions)
    Builder.new.build_sequence(expressions)
  end
end
