require 'atom'

class Word < Struct.new(:name)
  include Atom

  def to_s
    name
  end
end
