require 'ast/builder'

class Parser
  def parse(string)
    self.string = string
    parse_everything
  end

  def self.parse(string)
    self.new.parse(string).call(AST::Builder.new)
  end

  private

  attr_reader :string

  def string=(string)
    @string = string.strip
  end

  def parse_everything
    expression = parse_sequence
    read %r{\z}

    expression
  end

  def parse_sequence
    expressions = []
    expressions << parse_expression until can_read? %r{\)|\z}

    if expressions.length == 1
      expressions.first
    else
      -> builder { builder.build_sequence(expressions.map { |e| e.call(builder) }) }
    end
  end

  def parse_expression
    if can_read? %r{\(}
      parse_brackets
    elsif can_read? %r{_}
      parse_variable
    elsif can_read? %r{[^\p{Blank}()]+}
      parse_keyword
    else
      complain
    end
  end

  def parse_brackets
    read %r{\(}
    expression = parse_sequence
    read %r{\)}

    expression
  end

  def parse_variable
    read %r{_}
    name = read_name
    -> builder { builder.build_variable(name) }
  end

  def parse_keyword
    name = read_name
    -> builder { builder.build_keyword(name) }
  end

  def read_name
    read %r{[^\p{Blank}()]+}
  end

  def can_read?(pattern)
    !try_match(pattern).nil?
  end

  def read(pattern)
    match = try_match(pattern) || complain(pattern)
    self.string = match.post_match
    match.to_s
  end

  def try_match(pattern)
    /\A#{pattern}/.match(string)
  end

  def complain(expected = nil)
    complaint = "unexpected #{string.slice(0)}"
    complaint << ", expected #{expected.inspect}" if expected

    raise complaint
  end
end
