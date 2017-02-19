require 'atom'

class Variable < Struct.new(:name, :scope)
  include Atom

  def to_s
    "_#{name}"
  end
end
