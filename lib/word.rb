require 'atom'

class Word < Struct.new(:name)
  include Atom

  def to_s
    name
  end

  def find_variable(name)
    nil
  end
end
