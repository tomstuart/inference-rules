module Atom
  def inspect
    "«#{to_s}»"
  end

  def bracketed
    to_s
  end
end
