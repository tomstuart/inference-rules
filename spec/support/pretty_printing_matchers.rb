module PrettyPrintingMatchers
  extend RSpec::Matchers::DSL

  matcher :look_like do |expected|
    match do |actual|
      actual.to_s == expected
    end
  end
end
