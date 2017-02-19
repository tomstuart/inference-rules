require 'atom'

class Formula < Struct.new(:parts)
  include Atom

  def to_s
    parts.map(&:bracketed).join(' ')
  end

  def bracketed
    "(#{to_s})"
  end
end
