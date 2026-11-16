# Boarded / alighted alerts of School Bus children linked to a Family, written by Occurrences::MarkPassengers after the
# driver (or the office) ticks them. Morning: boarded at the child's stop (tap opens Live Tracking), alighted = arrived at
# school; afternoon: boarded at school, alighted = dropped off at the stop. Once per child, run and state.
#   Attendance.call(occ:, marks: [[rid, "boarded" | "alighted"]])
module ConvoyApp
  module Alerts
    class Attendance < ApplicationService
      def initialize(occ:, marks:)
        @occ = occ
        @marks = marks
      end

      def call
        route = @occ.school_route
        return 0 if route.nil? || @marks.empty?

        school = route.plan.school
        kids = Alerts.kids(@marks.map { [ school.id, it.first ] })
        return 0 if kids.empty?

        stops = SchoolRouteStop.where(school_route_id: route.id).includes(:riders).to_a
        am = route.plan.session == "am"
        plate = @occ.vehicle&.plate
        Alerts.write(@marks.flat_map do |rid, state|
          kid = kids[[ school.id, rid ]] or next []
          stop = stops.find { |s| s.riders.any? { it.rid == rid } }&.name
          name = kid.dependant.name
          title, body = if state == "boarded"
                          [ "#{name} boarded", "Boarded #{"Bus #{plate} " if plate}at #{am ? stop : school.name}." ]
          else
                          [ "#{name} alighted", am ? "Arrived at #{school.name}." : "Dropped off at #{stop}." ]
          end
          Alerts.rows_for(kid.account_ids, kind: "school_#{state}", title:, body:, company_id: @occ.company_id, occurrence_id: @occ.id,
                                           occurrence_date: @occ.date, dependant_id: kid.dependant.id, target: (am && state == "boarded" ? "live" : nil),
                                           target_id: (am && state == "boarded" ? kid.dependant.id : nil), dedupe_key: "school:#{state}:#{@occ.id}:#{@occ.date}:#{rid}")
        end)
      end
    end
  end
end
