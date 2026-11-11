require "rails_helper"

RSpec.describe TripStop, :tenant do
  it "stores a blank Street View link as nil" do
    expect(described_class.new(street_view_url: "").street_view_url).to be_nil
    expect(described_class.new(street_view_url: "  ").street_view_url).to be_nil
  end

  it "keeps a Street View link as given" do
    link = "https://maps.app.goo.gl/abc"
    expect(described_class.new(street_view_url: link).street_view_url).to eq(link)
  end

  describe "as a run of a direction travels it" do
    let(:pickup) { described_class.new(direction: 1, use: "pu", name: "A", return_name: "A Bay") }

    it "swaps pick-up / drop-off and takes the return name on the way back" do
      expect(pickup.use_in(2)).to eq("do")
      expect(pickup.name_in(2)).to eq("A Bay")
      expect(described_class.new(direction: 1, use: "do", name: "B").use_in(2)).to eq("pu")
    end

    it "keeps both and via, and falls back to the name when the return name is blank" do
      expect(described_class.new(direction: 1, use: "both", name: "C").use_in(2)).to eq("both")
      expect(described_class.new(direction: 1, use: "via", name: "D", return_name: "").use_in(2)).to eq("via")
      expect(described_class.new(direction: 1, use: "pu", name: "E", return_name: "").name_in(2)).to eq("E")
    end

    it "leaves the way there and a separate return's own stops as entered" do
      expect([ pickup.use_in(1), pickup.name_in(1) ]).to eq([ "pu", "A" ])
      own = described_class.new(direction: 2, use: "pu", name: "MBC", return_name: "ignored")
      expect([ own.use_in(2), own.name_in(2) ]).to eq([ "pu", "MBC" ])
    end
  end
end
