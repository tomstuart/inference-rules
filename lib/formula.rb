require 'atom'

class Formula < Struct.new(:parts)
  include Atom

  def to_s
    parts.map(&:to_s).join(' ')
  end
end
