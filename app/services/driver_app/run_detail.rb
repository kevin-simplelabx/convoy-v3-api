# Trip Details in the Driver app: the run card plus everything the driver reads before and during the trip — trip
# value, notes, airport and disposal blocks, Day n of N, standby, attachments, Point of Contact, the main contractor's
# app, the replacement, the points (map and stop list with what was recorded), the names and Before You Go.
module DriverApp
  class RunDetail < ApplicationService
    def initialize(member:, occ:)
      @member = member
      @occ = occ
      @trip = occ.trip
    end

    def call
      points = Occurrences::Stops.detailed(@occ)
      passengers = Occurrences::Passengers.call(@occ, points:)
      RunList.new(member: @member, runs: [ @occ ]).card(@occ).merge(
        trip_value: Runs.trip_value(@occ, @member), notes: @trip&.notes, airport:, disposal:, series:, standby:, attachments:,
        contacts:, contractor:, replacement:, points: with_record(points, passengers), passengers:,
        before_you_go: { not_riding: not_riding(passengers, points), skipped_points: skipped_points(points) },
        expected_pax: passengers.any? ? passengers.count { !it[:state].in?(%w[bus_not_required not_boarding]) } : @occ.pax
      )
    end

    private

    def with_record(points, passengers)
      events = @occ.stop_events.index_by(&:position)
      points.each_with_index.map do |p, i|
        e = events[p[:position]]
        p.slice(:position, :name, :address, :lat, :lng, :planned_time, :note, :pickup, :dropoff, :waypoint, :school, :photos,
                :street_view_url, :vias).merge(
          number: i + 1, lat: p[:lat]&.to_f, lng: p[:lng]&.to_f,
          pickups: passengers.count { it[:pickup_position] == p[:position] }, dropoffs: passengers.count { it[:dropoff_position] == p[:position] },
          record: e && { arrived_at: e.arrived_at, departed_at: e.departed_at, skipped: e.skipped, boarded: e.boarded, alighted: e.alighted }
        )
      end
    end

    # Points skipped today in Edit Route.
    def skipped_points(points)
      planned = @occ.stop_events.select(&:planned_skip).map(&:position)
      points.select { planned.include?(it[:position]) }.map { { position: it[:position], name: it[:name] } }
    end

    # Children not riding today, at their own stop (the pick-up in the morning, the drop-off in the afternoon).
    def not_riding(passengers, points)
      names = points.to_h { [ it[:position], it[:name] ] }
      school = (points.find { it[:school] } || (@trip&.session == "pm" ? points.first : points.last))&.dig(:position)
      passengers.select { it[:state].in?(%w[bus_not_required not_boarding]) }.map do |p|
        at = p[:pickup_position] == school ? p[:dropoff_position] : p[:pickup_position]
        { id: p[:id], name: p[:name], point: names[at], state: p[:state], reason: p[:reason] }
      end
    end

    def airport
      return unless @trip&.airport_transfer?

      { direction: @trip.airport_direction, flight_number: @trip.flight_number, flight_time: @trip.flight_time_hm, terminal: @trip.terminal,
        wait_minutes: @trip.wait_minutes, meet_and_greet: @trip.meet_and_greet, signboard_name: @trip.signboard_name,
        luggage: @trip.luggage_on ? %i[cabin medium large extra_large oversized].to_h { [ it, @trip.public_send(:"luggage_#{it}") ] } : nil }
    end

    # The booked block and, once started, what the Driver app recorded with the block clock. Before the start, the
    # odometer the bus last ended a disposal on (Day n+1 of a multi-day booking starts from Day n's reading).
    def disposal
      return unless @trip&.disposal?

      d = @occ.disposal
      { hours: @trip.hours&.to_f, record: d && DriverDisposalBlueprint.render_as_hash(d.decorate),
        suggested_start_odometer: d ? nil : last_odometer }
    end

    def last_odometer
      return unless @occ.vehicle_id

      OccurrenceDisposal.joins("JOIN trip_occurrences o ON o.id = occurrence_disposals.occurrence_id AND o.date = occurrence_disposals.occurrence_date")
                        .where(o: { vehicle_id: @occ.vehicle_id }).where.not(end_odometer: nil).order(ended_at: :desc).pick(:end_odometer)
    end

    # Day n of N for a booking over several days (each day is its own trip).
    def series
      bt = @trip&.booking_trip or return nil
      days = bt.booking.days.sort_by(&:date)
      return nil if days.size < 2

      { day: days.index { it.id == bt.booking_day_id }.to_i + 1, of: days.size, title: bt.booking.number }
    end

    def standby
      s = @trip&.standby or return nil
      { location: s.location, address: s.address, lat: s.lat&.to_f, lng: s.lng&.to_f, minutes: s.minutes, report_time: Clock.hm(s.report_time),
        note: s.note, street_view_url: s.street_view_url, photos: s.photos.map { it.decorate.file_info(:photo, versions: [ :thumb ]) } }
    end

    def attachments = (@trip&.attachments || []).map { it.decorate.file_info(:file) }

    # Point of Contact: requestor, guest, the main contractor's contact; Operations is on GET /driver/company.
    def contacts
      return [] unless @trip

      [ ([ "requestor", @trip.requestor_name, @trip.requestor_phone ] if @trip.requestor_name.present?),
        ([ "guest", @trip.guest_name, @trip.guest_phone ] if @trip.guest_name.present? && !@trip.guest_is_requestor),
        ([ "main_contractor", @trip.contractor_contact_name, @trip.contractor_contact_phone ] if @trip.contractor_contact_name.present?) ]
        .compact.map { |role, name, phone| { role:, name:, phone: } }
    end

    # A sub-contracted trip the main contractor wants run in its own driver app (trip form: Requires contractor app).
    def contractor
      return unless @trip&.subcontracted?

      { name: @occ.client&.name, requires_app: @trip.require_contractor_app }
    end

    def replacement
      rep = @occ.replacement or return nil
      { kind: rep.kind, reason: rep.reason, driver_name: @occ.driver&.name || @occ.operator_driver&.name || @occ.driver_name,
        vehicle_plate: @occ.original_vehicle_id ? @occ.vehicle&.plate : nil, original_vehicle_plate: @occ.original_vehicle&.plate }
    end
  end
end
