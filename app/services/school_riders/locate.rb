# Places riders' homes on the map from their postal codes (OneMap, cached), and fills an empty address with OneMap's.
# For a whole list it also counts the riders OneMap does not know (No Location) and marks the list ready.
module SchoolRiders
  class Locate < ApplicationService
    def initialize(scope, dataset: nil)
      @scope = scope
      @dataset = dataset
    end

    def call
      @scope.where(lat: nil).distinct.pluck(:postal).each do |postal|
        point = Geo::OneMap.lookup(postal) or next

        @scope.where(postal:, lat: nil).update_all(lat: point[:lat], lng: point[:lng], updated_at: Time.current)
        @scope.where(postal:, address: [ nil, "" ]).update_all(address: point[:address])
      end
      @dataset&.update!(status: "ready", unlocated_count: @dataset.riders.where(lat: nil).count)
    end
  end
end
