# One Claude call that reads a file and/or text and replies with JSON matching a schema (structured outputs).
# Server-side fallback is on: a refused request is retried on a model the API picks.
module Ai
  class Extract < ApplicationService
    FALLBACK_BETA = "server-side-fallback-2026-07-01"

    Result = Data.define(:data, :model, :input_tokens, :output_tokens)

    def initialize(instructions:, schema:, attachment: nil, text: nil, effort: :medium, max_tokens: 16_000)
      @instructions = instructions
      @schema = schema
      @attachment = attachment
      @text = text
      @effort = effort
      @max_tokens = max_tokens
    end

    def call
      message = Ai.client.beta.messages.create(
        model: Ai::MODEL,
        max_tokens: @max_tokens,
        messages: [ { role: :user, content: } ],
        output_config: { effort: @effort, format: { type: :json_schema, schema: @schema } },
        betas: [ FALLBACK_BETA ],
        fallbacks: :default
      )
      raise Error, "Claude declined to read this" if message.stop_reason == :refusal
      raise Error, "The reply was cut off. Try a shorter file" if message.stop_reason == :max_tokens

      reply = message.content.select { |b| b.type == :text }.map(&:text).join
      Result.new(JSON.parse(reply), message.model.to_s, message.usage.input_tokens, message.usage.output_tokens)
    rescue JSON::ParserError
      raise Error, "The reply could not be read"
    rescue Anthropic::Errors::RateLimitError, Anthropic::Errors::InternalServerError, Anthropic::Errors::APIConnectionError
      raise Error, "Claude is busy right now. Try again in a minute"
    rescue Anthropic::Errors::AuthenticationError, Anthropic::Errors::PermissionDeniedError
      raise Error, "Reading with Claude is not set up (API key missing or not allowed)"
    rescue Anthropic::Errors::APIStatusError => e
      raise Error, "Claude could not read this (#{e.message.truncate(120)})"
    end

    private

    def content
      blocks = []
      blocks << Attachment.block(@attachment) if @attachment.present?
      blocks << { type: :text, text: [ @instructions, @text.presence ].compact.join("\n\n") }
      blocks
    end
  end
end
