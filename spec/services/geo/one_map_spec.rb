require "rails_helper"

# The real OneMap client (the other specs swap it for FakeOneMap): an answer that is an error is "cannot be reached", not
# "postal code not found", so nothing is cached for a week by mistake.
RSpec.describe Geo::OneMap do
  subject(:client) { described_class.new }

  def answer(body, status: 200) = instance_double(Faraday::Response, success?: status < 400, status:, body: body.to_json)

  it "finds a postal code" do
    allow(Faraday).to receive(:get).and_return(answer({ "results" => [ { "POSTAL" => "455789", "LATITUDE" => "1.3138", "LONGITUDE" => "103.9283", "BLK_NO" => "20", "ROAD_NAME" => "SIGLAP VIEW" } ] }))
    expect(client.search("455789")).to eq(lat: 1.3138, lng: 103.9283, address: "20 SIGLAP VIEW")
  end

  it "answers nil when OneMap does not know the postal code" do
    allow(Faraday).to receive(:get).and_return(answer({ "found" => 0, "results" => [] }))
    expect(client.search("999999")).to be_nil
  end

  it "raises Unavailable when OneMap answers with an error (for example a missing token)" do
    allow(Faraday).to receive(:get).and_return(answer({ "error" => "Authentication token missing.", "found" => 0, "results" => [] }))
    expect { client.search("455789") }.to raise_error(Geo::OneMap::Unavailable, /Authentication token missing/)
  end

  it "does not keep a refused lookup" do
    Geo::OneMap.client = client
    allow(Faraday).to receive(:get).and_return(answer({ "error" => "Authentication token missing.", "results" => [] }))
    expect { described_class.lookup("455789") }.to raise_error(Geo::OneMap::Unavailable)
    expect(PostalGeocode.where(postal: "455789")).to be_empty
  end
end
