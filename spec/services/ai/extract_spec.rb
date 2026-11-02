require "rails_helper"

RSpec.describe Ai::Extract, :tenant do
  let(:read) { DocumentRead.create!(kind: "log_card", file: fixture_file_upload("sample.pdf", "application/pdf")) }

  it "sends the file and a strict schema, with server-side fallback, and parses the reply" do
    fake_claude.reply = { plate: "PD3318K" }
    result = described_class.call(instructions: "Read it", schema: Ai::Schema.object(plate: :string), attachment: read.file)

    expect(result.data).to eq("plate" => "PD3318K")
    req = fake_claude.requests.last
    expect(req).to include(model: Ai::MODEL, fallbacks: :default, betas: [ "server-side-fallback-2026-07-01" ])
    expect(req.dig(:output_config, :format)).to include(type: :json_schema)
    expect(req.dig(:output_config, :format, :schema)).to include(additionalProperties: false, required: [ "plate" ])
    blocks = req[:messages].first[:content]
    expect(blocks.first).to include(type: :document)
    expect(blocks.first.dig(:source, :media_type)).to eq("application/pdf")
    expect(blocks.last).to eq(type: :text, text: "Read it")
  end

  it "turns a CSV into text" do
    csv = DocumentRead.create!(kind: "log_card", file: fixture_file_upload("route.csv", "text/csv"))
    described_class.call(instructions: "Read", schema: Ai::Schema.object(a: :string), attachment: csv.file)
    expect(fake_claude.requests.last[:messages].first[:content].first[:text]).to include("Tan Ah Kow | P3 | 460123")
  end

  it "raises a readable error on a refusal or an API error" do
    fake_claude.stop_reason = :refusal
    expect { described_class.call(instructions: "x", schema: {}) }.to raise_error(ApplicationService::Error, /declined/)

    fake_claude.stop_reason = :end_turn
    fake_claude.error = Anthropic::Errors::APIConnectionError.new(url: URI("https://api.anthropic.com"))
    expect { described_class.call(instructions: "x", schema: {}) }.to raise_error(ApplicationService::Error, /busy/)
  end
end
