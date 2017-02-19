require 'atom'

class Variable < Struct.new(:name, :scope)
  include Atom

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
