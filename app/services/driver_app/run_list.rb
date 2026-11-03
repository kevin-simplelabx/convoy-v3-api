# Run cards for Drive (Today / Tomorrow), Plan (a day) and the floating on-going trip: time, route, direction, client,
# points, expected passengers, status, New. School Bus cards count the route's children less Bus Not Required.
module DriverApp
  class RunList < ApplicationService
    def initialize(member:, runs:)
      @member = member
      @runs = runs
    end

    def call = @runs.map { card(it) }

    def card(occ)
      points = Occurrences::Stops.planned(occ).reject { it[:use] == "via" }
      points = with_school(occ, points)
      vehicle = occ.vehicle
      mine = Runs.mine?(occ, @member)
      status = Runs.status(occ, @member)
      {
        id: occ.id, date: occ.date, start_time: occ.start_time_hm, end_time: occ.end_time_hm, starts_at: occ.starts_at, ends_at: occ.ends_at,
        trip_label: occ.trip_label, title: occ.school_route&.title || occ.trip&.title, label: occ.school_route&.label || occ.trip&.label,
        kind: Runs.kind(occ), kind_label: Runs::KIND_LABELS[Runs.kind(occ)], direction: Runs.direction(occ), client: Runs.client(occ),
        status:, status_label: Runs::STATUS_LABELS[status], seen: occ.driver_seen_at.present? || !mine,
        started_at: occ.started_at, ended_at: occ.ended_at,
        points_count: points.size, first_point: points.first&.dig(:name), last_point: points.last&.dig(:name),
        expected_pax: expected(occ), requires: Runs.requires(occ), vehicle: vehicle && { id: vehicle.id, plate: vehicle.plate },
        replaced_by: (status == "replaced" ? replaced_by(occ) : nil)
      }
    end

    private

    def with_school(occ, points)
      return points unless occ.school_route

      school = { name: occ.school_route.plan.school.name }
      occ.school_route.plan.session == "am" ? points + [ school ] : [ school ] + points
    end

    # Children on the list less Bus Not Required (School Bus), else the planned passengers of the run.
    def expected(occ)
      return occ.pax unless occ.school_route

      session = occ.school_route.plan.session
      rids = occ.school_route.stops.flat_map { |s| s.riders.map(&:rid) }
      away = absences.fetch([ occ.school_route.plan.school_id, occ.date ], []).count { |a| rids.include?(a.rid) && a.covers?(session) }
      rids.size - away
    end

    def absences
      @absences ||= begin
        routes = @runs.select(&:school_route)
        routes.empty? ? {} : SchoolRiderAbsence.where(school_id: routes.map { it.school_route.plan.school_id }.uniq, date: routes.map(&:date).uniq)
                                               .group_by { [ it.school_id, it.date ] }
      end
    end

    def replaced_by(occ)
      name = occ.driver&.name || occ.operator_driver&.name || occ.driver_name
      { driver_name: name, vehicle_plate: occ.original_vehicle_id ? occ.vehicle&.plate : nil }
    end
  end
end
