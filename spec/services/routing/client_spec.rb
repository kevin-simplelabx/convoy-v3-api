require "rails_helper"

# The real routing client (the other specs swap it for FakeRouting): whatever the service does wrong — an old image with
# no /optimise (Express answers an HTML 404), an error JSON, no connection — is Unavailable, never a half answer.
RSpec.describe Routing::Client do
  subject(:client) { described_class.new }

  def stub_service(&block)
    stubs = Faraday::Adapter::Test::Stubs.new(&block)
    allow(Faraday).to receive(:new).and_wrap_original do |original, *args, &config|
      original.call(*args) { |f| config.call(f); f.adapter :test, stubs }
    end
  end

  it "returns the service's JSON" do
    stub_service { |s| s.post("/optimise") { [ 200, {}, { routes: [] }.to_json ] } }
    expect(client.optimise(routes: [])).to eq("routes" => [])
  end

  it "raises Unavailable on an HTML 404 (a service image without the route), naming the path for the log" do
    stub_service { |s| s.post("/optimise") { [ 404, { "Content-Type" => "text/html" }, "<pre>Cannot POST /optimise</pre>" ] } }
    expect { client.optimise(routes: []) }.to raise_error(Routing::Client::Unavailable, %r{POST /optimise answered 404})
  end

  it "raises Unavailable on an error JSON" do
    stub_service { |s| s.post("/optimise") { [ 500, {}, { error: "boom" }.to_json ] } }
    expect { client.optimise(routes: []) }.to raise_error(Routing::Client::Unavailable, /500: boom/)
  end

  it "raises Unavailable when the service cannot be reached" do
    stub_service { |s| s.post("/optimise") { raise Faraday::ConnectionFailed, "refused" } }
    expect { client.optimise(routes: []) }.to raise_error(Routing::Client::Unavailable, "refused")
  end
end
