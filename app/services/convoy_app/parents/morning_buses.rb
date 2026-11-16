# The Family's morning buses on each child's next bus day (Live Tracking chips, Home Up Next): the riding children grouped
# by the morning route they ride that day, those marked Bus Not Required (Bus Not Required from a parent) and those with no
# morning route yet. Every company's data is read inside that company. Only the Family's own children are listed.
#   MorningBuses.call(household) -> [Bus]
module ConvoyApp
  module Parents
    class MorningBuses < ApplicationService
      # key "<route id>-<date>"; kids / off: [{ dependant:, stop: }] riding / not required; no_route: children without a morning route.
      Bus = Data.define(:key, :company, :school, :date, :route, :occurrence_id, :kids, :off, :no_route) do
        def today? = date == Date.current
        def names = kids.map { it[:dependant].first_name }
      end

      def initialize(household)
        @household = household
      end

      def call
        RiderRequest.kids(@household).group_by(&:company).flat_map do |company, kids|
          Parents.within(company) do
            riders = FamilyRider.includes(school: :company).where(school: kids.map(&:school), rid: kids.map { it.rider.rid }).index_by { [ it.school_id, it.rid ] }
            groups = {}
            kids.each do |kid|
              fr = riders[[ kid.school.id, kid.rider.rid ]] or next
              ride = Ride.new(kid.dependant, fr)
              next unless ride.date && ride.sessions.include?("am")

              place = ride.place("am")
              key = place ? "#{place[:route].id}-#{ride.date}" : "none-#{kid.school.id}-#{ride.date}"
              g = groups[key] ||= { company:, school: kid.school, date: ride.date, route: place&.dig(:route), occ: place && ride.occurrence(place[:route])&.id,
                                    kids: [], off: [], no_route: [] }
              if place.nil? then g[:no_route] << kid.dependant
              elsif ride.absence&.covers?("am") then g[:off] << { dependant: kid.dependant, stop: place[:stop] }
              else g[:kids] << { dependant: kid.dependant, stop: place[:stop] }
              end
            end
            groups.map do |key, g|
              Bus.new(key:, company: g[:company], school: g[:school], date: g[:date], route: g[:route], occurrence_id: g[:occ], kids: g[:kids],
                      off: g[:off], no_route: g[:no_route])
            end
          end
        end.sort_by { [ it.date, it.route ? 0 : 1, it.route&.start_time.to_i, it.key ] }
      end
    end
  end
end
