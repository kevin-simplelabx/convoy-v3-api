# Claude API access for reading documents and messages.
# Key: Rails credentials anthropic.api_key, else ANTHROPIC_API_KEY. Model: CLAUDE_MODEL, else Claude Opus 5.5.
module Ai
  MODEL = ENV.fetch("CLAUDE_MODEL", "claude-opus-5-5")

  def self.client
    @client ||= begin
      key = Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]
      key ? Anthropic::Client.new(api_key: key, timeout: 300) : Anthropic::Client.new(timeout: 300)
    end
  end

  # Tests swap the client for a fake.
  def self.client=(client)
    @client = client
  end
end
