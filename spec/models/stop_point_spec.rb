require "rails_helper"

RSpec.describe StopPoint do
  it "stores a blank Street View link as nil" do
    expect(described_class.new(street_view_url: "").street_view_url).to be_nil
    expect(described_class.new(street_view_url: "  ").street_view_url).to be_nil
  end

  it "keeps a Street View link as given" do
    link = "https://maps.app.goo.gl/abc"
    expect(described_class.new(street_view_url: link).street_view_url).to eq(link)
  end
end
