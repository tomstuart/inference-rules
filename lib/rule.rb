require 'parser'
require 'ast/builder'
require 'ast/lazy_builder'

class Rule
  def initialize(premises, conclusion)
    self.premises, self.conclusion = premises, conclusion
  end

  def self.define(premises: [], conclusion:)
    parser = Parser.new(AST::LazyBuilder.new)
    new(premises.map(&parser.method(:parse)), parser.parse(conclusion))
  end

  def to_s
    builder = AST::Builder.new
    premises_string = premises.map { |p| p.call(builder).to_s }.join('  ')
    conclusion_string = conclusion.call(builder).to_s

    [
      (premises_string unless premises_string.empty?),
      '-' * [premises_string, conclusion_string].map(&:length).max,
      conclusion_string
    ].compact.join("\n")
  end

  Match = Struct.new(:premises, :state) do
    def try_premises
      premises.inject([state]) { |states, premise|
        states.flat_map { |state| yield(premise, state) }
      }
    end
  end

  def match(expression, state)
    builder = AST::Builder.new
    next_state = state.unify(expression, conclusion.call(builder))
    Match.new(premises.map { |p| p.call(builder) }, next_state) if next_state
  end

  private

  attr_accessor :premises, :conclusion
end
