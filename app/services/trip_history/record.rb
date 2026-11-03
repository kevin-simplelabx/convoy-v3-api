# One run's record in Trip History: what happened (outcome, why it did not run), the vehicle and crew, the stops
# (planned, and what happened at each), the trip's details, the passengers (School Run), the driver's report, changes,
# corrections, notes and a log in time order. Corrected values are shown; `was` holds what was recorded.
module TripHistory
  class Record
    INCLUDES = [ :vehicle, :original_vehicle, :driver, :operator_driver, :operator, :client, :cancelled_by, :issue_raised_by,
                 { history_notes: :author, driver_report: :photos, correction: [ :vehicle, :driver, :stops, { logs: :user } ],
                   stop_events: [], trip_summary: [], company: [], replacement: %i[vehicle driver operator_driver], disposal: %i[runs extensions],
                   trip: [ :standby, :created_by, { stops: [], runs: :times } ], trip_run: :times,
                   passenger_marks: [], school_route: [ :attendant, { stops: [ :riders, :stop_point, { stop: :points } ], plan: :school } ] } ].freeze

    def self.call(occ) = new(occ).call

    def initialize(occ)
      @occ = occ
      @trip = occ.trip
      @company = occ.company
    end

    def call
      outcome = TripHistory.outcome(@occ)
      {
        id: @occ.id, key: @occ.decorate.key, date: @occ.date, trip_label: @occ.trip_label, title: @occ.decorate.title, kind: @occ.kind,
        kind_name: @occ.school_route_id ? "School Route" : Trip::KIND_NAMES[@occ.kind], trip_id: @occ.trip_id, school_route_id: @occ.school_route_id,
        client: @occ.client&.slice(:id, :name), start_time: @occ.start_time_hm, end_time: @occ.end_time_hm,
        outcome:, outcome_label: OUTCOMES.dig(outcome, :label), tone: OUTCOMES.dig(outcome, :tone),
        on_time: TripHistory.on_time(@occ, @company.on_time_minutes), on_time_minutes: @company.on_time_minutes,
        needs_look: TripHistory.needs_look?(@occ), not_run:, corrected: TripHistory.corrected?(@occ), can_correct: @occ.completed?,
        correction_lock_version: @occ.correction&.lock_version, was:,
        vehicle: used_vehicle, original_vehicle: vehicle(@occ.original_vehicle),
        operator: @occ.operator&.slice(:id, :name, :kind), crew:, stops:, stop_summary:, has_track: @occ.trip_summary&.ping_count.to_i.positive?,
        speed:, driving_summary:, trip_info:, standby:, point_of_contact:,
        passengers:, driver_report:, issue:,
        replacement: @occ.replacement && ReplacementBlueprint.render_as_hash(@occ.replacement.decorate),
        driver_end: @occ.driver_end && { kind: @occ.driver_end, reason: @occ.driver_end_reason, on_board: @occ.end_on_board },
        disposal: @occ.disposal && DriverDisposalBlueprint.render_as_hash(@occ.disposal.decorate),
        changes:, corrections:, notes: notes, log:
      }
    end

    private

    # The Passenger List: School Run (the route list) or School Bus (the route's children), with what was marked on the run.
    def passengers
      if @occ.school_route then Occurrences::Passengers.stop_list(@occ)
      elsif @trip&.school_run? then SchoolRuns::Passengers.call(@occ)
      end
    end

    # Why it did not run: the calendar's reason, or who cancelled it and for whom.
    def not_run
      if @occ.skipped? then { kind: "skipped", reason: @occ.skip_reason }
      elsif @occ.cancelled?
        { kind: "cancelled", by_client: @occ.cancelled_by_client, by: @occ.cancelled_by&.name, at: @occ.cancelled_at }
      end
    end

    def vehicle(v)
      v && { id: v.id, plate: v.plate, make: v.make, model: v.model, seats: v.seats, ownership: v.ownership,
             photo: v.decorate.photo_info, default_picture: v.decorate.default_picture }
    end

    def crew
      info = @occ.decorate.driver_info
      c = @occ.correction
      info = { kind: c.driver ? "own" : "corrected", id: c.driver&.id, name: c.driver_name, phone: c.driver&.phone } if c&.driver_name
      { driver: info, attendant: @occ.school_route&.attendant&.slice(:id, :name, :phone) }
    end

    # Recorded values that Correct Record changed: { outcome_label, plate, driver_name } (only those corrected).
    def was
      c = @occ.correction
      return {} unless c

      { outcome_label: c.outcome && OUTCOMES.dig(TripHistory.recorded_outcome(@occ), :label),
        plate: c.vehicle_plate && (@occ.vehicle&.plate || "N/A"),
        driver_name: c.driver_name && (TripHistory.recorded_driver_name(@occ) || "N/A") }.compact
    end

    def used_vehicle
      used = TripHistory.vehicle(@occ)
      used[:vehicle] ? vehicle(used[:vehicle]) : used[:plate] && { id: nil, plate: used[:plate] }
    end

    # Stops in travel order: planned against what happened (TripHistory.stop_record).
    def stops = @stops ||= TripHistory.stop_record(@occ, @company.on_time_minutes)

    # The stop record's header: distance, time on the road, stops served / skipped, late stops, riders boarded.
    def stop_summary
      return nil unless @occ.completed?

      t = @occ.trip_summary
      served = stops.count { |s| s[:served] && !s[:skipped] }
      { distance_km: t&.distance_km, duration_minutes: t&.duration_minutes, started_at: t&.started_at, ended_at: t&.ended_at,
        stops_total: stops.size, stops_served: served, stops_skipped: stops.count { |s| s[:skipped] },
        late_stops: stops.select { |s| s[:late] }.map { |s| s[:position] + 1 }, boarded: TripHistory.pax(@occ) }
    end

    def speed
      t = @occ.trip_summary
      t&.max_speed_kmh && { max_kmh: t.max_speed_kmh, avg_moving_kmh: t.avg_moving_speed_kmh, limit_kmh: t.speed_limit_kmh,
                            overspeed_seconds: t.overspeed_seconds }
    end

    def driving_summary
      t = @occ.trip_summary
      return nil unless t&.started_at

      planned = @occ.end_time - @occ.start_time
      { distance_km: t.distance_km, duration_minutes: t.duration_minutes, planned_minutes: planned,
        vs_plan_minutes: t.duration_minutes - planned, odometer_start_km: t.odometer_start_km, odometer_end_km: t.odometer_end_km,
        idle_minutes: (t.idle_seconds.to_i / 60.0).round, harsh_events: t.harsh_events, ping_count: t.ping_count,
        ping_interval_seconds: t.ping_interval_seconds, fuel_used: t.fuel_used, fuel_unit: t.fuel_unit, fuel_estimated: t.fuel_estimated }
    end

    def trip_info
      return { route: @occ.decorate.route_text, price: @occ.price, trip_value: @occ.trip_value } unless @trip

      { kind_name: @trip.kind_name, label: @trip.label, recurrence: recurrence, run: @occ.trip_run&.label, price: @occ.price,
        trip_value: @occ.trip_value, operator_cost: @occ.operator_cost, business_unit: @trip.business_unit, project: @trip.project,
        booking_ref: @trip.booking_ref, notes: @trip.notes, pax: @occ.pax }
    end

    def recurrence
      return "One-off" unless @trip.recurring?

      days = @trip.days.sort_by { |d| (d + 6) % 7 }.map { |d| DAY_NAMES[d] }
      days == %w[Mon Tue Wed Thu Fri] ? "Mon to Fri" : days.join(", ")
    end

    def standby
      s = @trip&.standby
      s && { location: s.location, minutes: s.minutes, report_time: Clock.hm(@occ.start_time - s.minutes), note: s.note }
    end

    def point_of_contact
      return nil unless @trip

      { requestor: { name: @trip.requestor_name, email: @trip.requestor_email, phone: @trip.requestor_phone },
        guest: @trip.guest_is_requestor ? nil : { name: @trip.guest_name, phone: @trip.guest_phone } }
    end

    def driver_report
      r = @occ.driver_report
      r && { driver_name: r.driver_name, note: r.note, submitted_at: r.submitted_at,
             photos: r.photos.map { |p| { id: p.id, caption: p.caption }.merge(p.decorate.file_info(:image)) } }
    end

    def issue
      @occ.issue? ? { reason: @occ.issue_reason, by: @occ.issue_raised_by&.name, at: @occ.issue_raised_at } : nil
    end

    def audits = @audits ||= @occ.audits.includes(:user).order(:created_at).to_a

    def changes
      audits.select { |a| a.action == "update" }.map { |a| { at: a.created_at, by: a.user&.name, changes: a.audited_changes } }
    end

    def corrections
      Array(@occ.correction&.logs).map { |l| { at: l.created_at, by: l.user&.name, reason: l.reason, items: l.items } }
    end

    # Arrived / departed / skipped at each stop (from the stop record, corrected times included).
    def stop_log
      plate = TripHistory.vehicle(@occ)[:plate] || "The vehicle"
      last = stops.size - 1
      stops.select { |s| s[:served] }.flat_map do |s|
        arr = at(s[:arrived_at])
        dep = at(s[:departed_at])
        next [ { at: arr, text: "#{plate} skipped #{s[:name]}. No passenger to pick up", by: nil } ] if s[:skipped]

        late = s[:late] ? ", #{s[:delay_minutes]} min late" : ""
        first = s[:position].zero? ? { at: arr, text: "#{plate} started the trip at #{s[:name]}#{late}", by: nil } : nil
        reach = s[:position].zero? ? nil : { at: arr, text: "#{plate} arrived at #{s[:name]}#{late}", by: nil }
        leave = s[:position] == last ? { at: dep || arr, text: "#{plate} ended the trip at #{s[:name]}", by: nil } : { at: dep, text: "#{plate} departed from #{s[:name]}", by: nil }
        [ first, reach, leave ].compact
      end
    end

    # A minute of the run's day ("08:03", may pass midnight) as a time.
    def at(hm)
      return nil unless hm

      minute = Clock.minutes(hm)
      minute += 1440 while minute < @occ.start_time - 720
      @occ.starts_at + (minute - @occ.start_time).minutes
    end

    def notes = @occ.history_notes.map { |n| { id: n.id, body: n.body, by: n.author&.name, at: n.created_at } }

    # Newest first: trip created, changes, replacement, run start / end, what happened at each stop, report, notes.
    def log
      items = []
      items << { at: @trip.created_at, text: "Trip created", by: @trip.created_by&.name } if @trip
      audits.select { |a| a.action == "update" }.each { |a| items << { at: a.created_at, text: "Run changed: #{a.audited_changes.keys.join(', ')}", by: a.user&.name } }
      items << { at: @occ.replacement.created_at, text: "Replacement arranged", by: nil } if @occ.replacement
      items << { at: @occ.cancelled_at, text: @occ.cancelled_by_client ? "Cancelled at the client's request" : "Cancelled", by: @occ.cancelled_by&.name } if @occ.cancelled?
      items << { at: @occ.starts_at, text: "Planned start", by: nil } if @occ.completed?
      items << { at: @occ.ended_at || @occ.ends_at, text: "Run completed", by: nil } if @occ.completed?
      items.concat(stop_log)
      items << { at: @occ.driver_report.submitted_at, text: "Driver's report sent", by: @occ.driver_report.driver_name } if @occ.driver_report
      @occ.history_notes.each { |n| items << { at: n.created_at, text: "Note added", by: n.author&.name } }
      corrections.each { |c| items << { at: c[:at], text: "Record corrected: #{c[:reason]}", by: c[:by] } }
      items.compact.select { |i| i[:at] }.sort_by { |i| i[:at] }.reverse
    end
  end
end
