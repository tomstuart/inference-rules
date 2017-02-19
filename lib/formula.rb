require 'atom'

class Formula < Struct.new(:parts)
  include Atom

  def to_s
    parts.map { |p| p.is_a?(Formula) ? "(#{p.to_s})" : p.to_s }.join(' ')
  end
end
