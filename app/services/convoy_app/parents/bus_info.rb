# Convoy App › Bus Information: a riding child's bus for the morning pick-up or the afternoon drop-off on their next bus
# day — the bus (plate, seats, model), route, the child's own stop and times, the days the plan runs, the crew (driver and
# bus attendant with phones), how many adults can receive the child, and whether Track Bus shows. Read inside the
# rider's company.
module ConvoyApp
  module Parents
    class BusInfo < ApplicationService
      DAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

      def initialize(member:, dependant_id:, session: nil)
        @household = member.household
        @dependant = @household.dependants.find { it.id == dependant_id.to_i } or raise ActiveRecord::RecordNotFound
        @session = session.to_s
      end

      def call
        kid = RiderRequest.kids(@household).find { it.dependant.id == @dependant.id } or raise ActiveRecord::RecordNotFound
        Parents.within(kid.company) do
          fr = FamilyRider.includes(school: :company).find_by!(school: kid.school, rid: kid.rider.rid)
          ride = Ride.new(@dependant, fr)
          session = ride.sessions.include?(@session) ? @session : ride.sessions.first
          leg = ride.leg(session)
          place = ride.place(session)
          route = place&.dig(:route)
          v = route && ride.vehicle(route)
          board = ConvoyApp::Households::GuardianBoard.call(household: @household, dependant_id: @dependant.id).first
          { child: { dependant_id: @dependant.id, name: @dependant.name, first_name: @dependant.first_name, level: kid.rider.grade || @dependant.level,
                     school: kid.school.name },
            company: Parents.company_json(kid.company), sessions: ride.sessions, session:, date: ride.date, status: { label: leg[:status], tone: leg[:tone] },
            bus: v && { plate: v.plate, seats: v.seats, model: [ v.make, v.model ].compact_blank.join(" ").presence, size: route.bus_size(v) },
            rows: route ? rows(session, place, route) : [], crew: route ? ride.crew(route) : [],
            guardians: { count: board[:can_receive], text: "#{board[:can_receive]} #{board[:can_receive] == 1 ? 'person' : 'people'} can receive #{@dependant.first_name}" },
            can_track: ride.can_track? }
        end
      end

      private

      def rows(session, place, route)
        stop = place[:stop]
        days = days_text(place[:plan].days)
        if session == "am"
          [ [ "Route", route.title ], [ "Pick-up Point", stop&.name ], [ "Pick-up Time", stop&.scheduled_time_hm ], [ "Arrive at School", route.end_time_hm ], [ "Days", days ] ]
        else
          [ [ "Route", route.title ], [ "Leaves School", route.start_time_hm ], [ "Drop-off Point", stop&.name ], [ "Drop-off Time", stop&.scheduled_time_hm ], [ "Days", days ] ]
        end.map { |k, v| { key: k, value: v } }
      end

      # [1..5] -> "Mon to Fri"; otherwise the days listed.
      def days_text(days)
        list = days.sort
        return "#{DAYS[list.first - 1]} to #{DAYS[list.last - 1]}" if list.size > 2 && list.last - list.first == list.size - 1

        list.map { DAYS[it - 1] }.join(", ")
      end
    end
  end
end
