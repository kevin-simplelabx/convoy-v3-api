# A stand-in for the Claude client: records each request and replies with the JSON a test sets.
class FakeClaude
  Block = Struct.new(:type, :text)
  Usage = Struct.new(:input_tokens, :output_tokens)
  Reply = Struct.new(:content, :stop_reason, :model, :usage)

  attr_reader :requests
  attr_accessor :reply, :stop_reason, :error

  def initialize
    @requests = []
    @reply = {}
    @stop_reason = :end_turn
  end

  def beta = self
  def messages = self

  def create(**params)
    @requests << params
    raise error if error

    Reply.new([ Block.new(:text, reply.to_json) ], stop_reason, Ai::MODEL.to_sym, Usage.new(1200, 80))
  end
end

module FakeClaudeHelper
  def fake_claude = @fake_claude ||= FakeClaude.new
end

RSpec.configure do |config|
  config.include FakeClaudeHelper
  config.before { Ai.client = fake_claude }
  config.after { Ai.client = nil }
end
