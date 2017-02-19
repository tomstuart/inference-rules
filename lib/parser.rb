require 'builder'

class Parser
  def initialize(builder = Builder.new)
    self.builder = builder
  end

  def parse(string)
    self.string = string
    parse_everything
  end

  def self.parse(string)
    self.new.parse(string)
  end

  private

  attr_accessor :builder
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
      builder.build_sequence(expressions)
    end
  end

  def parse_expression
    if can_read? %r{\(}
      parse_brackets
    elsif can_read? %r{_}
      parse_variable
    elsif can_read? %r{[^\p{Blank}()]+}
      parse_word
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
    builder.build_variable(read_name)
  end

  def parse_word
    builder.build_word(read_word)
  end

  def read_name
    read %r{_}
    read_word
  end

  def read_word
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
