# Who a replacement's message would reach, for the Notify box of the Replace dialog:
#   guests  the first NAMES distinct guest names (trip guest_name, plus names on the runs' passenger marks), how many
#           guests in all, and how many affected trips
#   parents the riders on the affected School Bus runs (route riders_count, once per run) and how many such runs
# runs = Replacements::Affected.runs(rep), or [] before an original vehicle is chosen: all zeros.
module Replacements
  class NotifyAudiences < ApplicationService
    NAMES = 3

    def initialize(runs)
      @runs = runs
    end

    def call
      { guests: guests, parents: parents }
    end

    private

    def guests
      names = (trip_names + passenger_names).map(&:strip).reject(&:blank?).uniq { it.downcase }
      { names: names.first(NAMES), count: names.size, trips: @runs.where.not(trip_id: nil).distinct.count(:trip_id) }
    end

    def parents
      per_route = @runs.where.not(school_route_id: nil).group(:school_route_id).count
      riders = SchoolRoute.where(id: per_route.keys).pluck(:id, :riders_count).sum { |id, n| n * per_route[id] }
      { riders:, routes: per_route.values.sum }
    end

    def trip_names
      Trip.where(id: @runs.where.not(trip_id: nil).select(:trip_id)).where.not(guest_name: [ nil, "" ]).order(:id).pluck(:guest_name)
    end

    def passenger_names
      OccurrencePassenger.where(occurrence_id: @runs.select(:id), occurrence_date: @runs.select(:date)).where.not(name: [ nil, "" ])
                         .order(:id).pluck(:name)
    end
  end
end
