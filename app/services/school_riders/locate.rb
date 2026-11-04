# Places riders' homes on the map from their postal codes (OneMap, cached), and fills an empty address with OneMap's.
# For a whole list it also counts the riders asked about so far (progress), those OneMap does not know (No Location),
# and marks the list ready.
module SchoolRiders
  class Locate < ApplicationService
    def initialize(scope, dataset: nil)
      @scope = scope
      @dataset = dataset
    end

    def call
      todo = @scope.where(lat: nil).group(:postal).count
      @dataset&.update!(checked_count: @dataset.riders_count - todo.values.sum)
      todo.each do |postal, n|
        point = Geo::OneMap.lookup(postal)
        @dataset&.increment!(:checked_count, n) # rubocop:disable Rails/SkipsModelValidations
        next unless point

        @scope.where(postal:, lat: nil).update_all(lat: point[:lat], lng: point[:lng], updated_at: Time.current)
        @scope.where(postal:, address: [ nil, "" ]).update_all(address: point[:address])
      end
      @dataset&.update!(status: "ready", unlocated_count: @dataset.riders.where(lat: nil).count)
    end
  end
end
