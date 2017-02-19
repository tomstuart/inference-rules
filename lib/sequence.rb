require 'atom'

class Sequence < Struct.new(:parts)
  include Atom

  def to_s
    parts.map(&:bracketed).join(' ')
  end

  def bracketed
    "(#{to_s})"
  end

  def find_variable(name)
    parts.each do |part|
      result = part.find_variable(name)
      return result if result
    end

    nil
  end
end
