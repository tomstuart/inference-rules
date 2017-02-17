require 'atom'

class Variable < Struct.new(:name, :scope)
  include Atom

  def to_s
    name
  end
end
