# Finds each of a study's student postal codes on OneMap (prototype fzGeo), keeping the answers in postal_geocodes. A
# code is tried up to three times; when OneMap keeps failing for several codes in a row the rest are left for Check Again.
# Returns { points: { postal => { lat, lng, address } | nil (not found) }, unreachable: [postals] }.
module Feasibility
  class Geocode < ApplicationService
    RETRY_DELAYS = [ 0.6, 1.2 ].freeze
    GIVE_UP_AFTER = 3 # codes in a row that OneMap could not answer

    def initialize(study)
      @study = study
    end

    def call
      postals = @study.rows.map(&:postal).uniq
      cached = PostalGeocode.where(country: "SG", postal: postals).reject(&:stale?).index_by(&:postal)
      points = cached.transform_values(&:point)
      unreachable = []
      failed = 0
      (postals - cached.keys).each do |pc|
        next unreachable << pc if failed >= GIVE_UP_AFTER

        points[pc] = lookup(pc)
        failed = 0
      rescue Geo::OneMap::Unavailable
        unreachable << pc
        failed += 1
      end
      { points:, unreachable: }
    end

    private

    def lookup(postal)
      attempts = 0
      begin
        Geo::OneMap.lookup(postal)
      rescue Geo::OneMap::Unavailable
        delay = RETRY_DELAYS[attempts]
        raise unless delay

        attempts += 1
        sleep(delay)
        retry
      end
    end
  end
end
