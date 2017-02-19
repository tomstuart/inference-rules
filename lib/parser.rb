class Parser
  def initialize(builder)
    @builder = builder
  end

  def parse_complete_formula(string)
    self.string = string
    parse_everything { parse_formula }
  end

  def parse_complete_term(string)
    self.string = string
    parse_everything { parse_term }
  end

  private

  attr_reader :builder, :string

  def string=(string)
    @string = string.strip
  end

  def parse_everything
    result = yield
    complain unless string.empty?
    result
  end

  def parse_formula
    left = parse_term
    symbol = read %r{→|∈}
    right = parse_term

    case symbol
    when '→'
      builder.build_evaluates(left, right)
    when '∈'
      builder.build_element_of(left, right)
    else
      complain
    end
  end

  def parse_term
    if can_read? %r{\(}
      parse_brackets
    elsif can_read? %r{if}
      parse_conditional
    elsif can_read? %r{true|false}
      parse_boolean
    elsif can_read? %r{0}
      parse_zero
    elsif can_read? %r{succ|pred|iszero}
      parse_numeric_operation
    elsif can_read? %r{[[:upper:]]+}
      parse_constant
    elsif can_read? %r{_[^\p{Blank}()]+}
      parse_variable
    else
      complain
    end
  end

  def parse_brackets
    read %r{\(}
    term = parse_term
    read %r{\)}

    term
  end

  def parse_conditional
    read %r{if}
    condition = parse_term
    read %r{then}
    consequent = parse_term
    read %r{else}
    alternative = parse_term

    builder.build_conditional(condition, consequent, alternative)
  end

  def parse_boolean
    case read_boolean
    when 'true'
      builder.build_true
    when 'false'
      builder.build_false
    else
      complain
    end
  end

  def parse_zero
    read %r{0}
    builder.build_zero
  end

  def parse_numeric_operation
    numeric_operation = read_numeric_operation
    argument = parse_term

    case numeric_operation
    when 'succ'
      builder.build_succ(argument)
    when 'pred'
      builder.build_pred(argument)
    when 'iszero'
      builder.build_iszero(argument)
    else
      complain
    end
  end

  def parse_constant
    builder.build_constant(read_constant)
  end

  def parse_variable
    builder.build_variable(read_name)
  end

  def read_boolean
    read %r{true|false}
  end

  def read_numeric_operation
    read %r{succ|pred|iszero}
  end

  def read_constant
    read %r{[[:upper:]]+}
  end

  def read_name
    read %r{_}
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
