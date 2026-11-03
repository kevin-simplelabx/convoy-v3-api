# A stand-in for OneMap: known postal codes answer with a point near the school in the specs; others are not found.
class FakeOneMap
  attr_reader :searches
  attr_accessor :down

  def initialize
    @searches = []
    @points = {}
  end

  def add(postal, lat, lng, address = "Blk #{postal}") = @points[postal] = { lat:, lng:, address: }

  def search(postal)
    raise Geo::OneMap::Unavailable, "down" if down

    @searches << postal
    @points[postal]
  end
end

module FakeOneMapHelper
  def fake_one_map = @fake_one_map ||= FakeOneMap.new
end

RSpec.configure do |config|
  config.include FakeOneMapHelper
  config.before { Geo::OneMap.client = fake_one_map }
  config.after { Geo::OneMap.client = nil }
end
