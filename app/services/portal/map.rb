# Client Portal › Map, today only (logic/app-feed.js liveTrips, schoolDayAll): the client's own runs on the sites the person
# covers, one activity at a time — the school sessions (Morning Pick-up, Afternoon Drop-off, CCA) of the schools linked
# to the client or those sites (SchoolLive), Bookings (the client's one-off trips; Members: only from their own bookings)
# and Shuttles. Each run: state (Portal::RunState), bus, driver, the next stop and ETA, and where the bus is only while
# On the way or Started on this client's run (a bus also runs for other clients). `run(id)` is one run in detail.
module Portal
  class Map
    ACTIVITIES = { "am" => "AM", "pm" => "PM", "asa" => "CCA", "bookings" => "Bookings", "shuttles" => "Shuttles" }.freeze
    SCHOOL = %w[am pm asa].freeze
    # What the list row says under the title (Client Portal logic/app-feed.js KIND, TRIP_LBL and the shuttle runs).
    SCHOOL_KINDS = { "am" => "School bus, morning", "pm" => "School bus, afternoon", "asa" => "School bus, CCA" }.freeze
    INCLUDES = [ :stop_events, :driver, :operator_driver, :school_route, { vehicle: :live_position, trip: [ :client_site, { stops: :client_site }, { booking_trip: :booking } ],
                                                          trip_run: :times } ].freeze

    def initialize(client_user:, site_id: nil, now: Time.current)
      @user = client_user
      @client = client_user.client
      @now = now
      @today = now.to_date
      @site = site_id.presence && @user.limit_to_sites(@client.sites, :id).find(site_id)
    end

    def call(activity: nil)
      found = activities
      pick = found.find { it[:key] == activity } || found.find { it[:on_road].positive? } || found.find { it[:next] } || found.first
      runs = pick ? runs_for(pick[:key]) : []
      { date: @today, now: @now, site: @site&.slice(:id, :name), sites: sites, activities: found.map { it.except(:next) }, activity: pick&.dig(:key),
        schools: schools.map { { id: it.id, name: it.name, lat: it.lat&.to_f, lng: it.lng&.to_f } },
        counts: RunState::LABELS.keys.index_with { |k| runs.count { it[:state] == k } }, runs: }
    end

    # One run in detail: a School Bus run (SchoolLive: students at each stop), or a trip run (its stops with planned and
    # recorded times).
    def run(id)
      occ = TripOccurrence.where(date: @today).find(id)
      if occ.school_route_id
        school = schools.find { it.id == occ.school_route.plan.school_id } or raise ActiveRecord::RecordNotFound
        return school_run(school, occ)
      end
      raise ActiveRecord::RecordNotFound unless trip_runs.exists?(id: occ.id)

      occ = TripOccurrence.where(date: @today).includes(*INCLUDES).find(id)
      trip_row(occ).merge(stops: stops(occ))
    end

    # Find a student (name, level, rider id) on today's School Bus runs: each leg with the route, the bus, the stop and
    # their status; up to 6.
    def students(query)
      q = query.to_s.strip.downcase
      return [] if q.size < 2

      schools.flat_map do |school|
        SchoolLive.runs(school, @today).flat_map do |session, list|
          ctx = SchoolLive.context(school, @today, list)
          list.flat_map do |occ|
            run = SchoolLive::Run.new(occ, school:, now: @now, **ctx)
            run.riders.select { [ it[:name], it[:level], it[:rid] ].compact.any? { |v| v.to_s.downcase.include?(q) } }.map do |k|
              stop = run.stops[k[:stop][:index]]
              { rid: k[:rid], name: k[:name], level: k[:level], school: school.name, session:, session_label: ACTIVITIES.fetch(session),
                run_id: occ.id, route: run.route.label, plate: occ.vehicle&.plate, stop: k[:stop][:name], planned_at: stop[:planned_at],
                status: k[:status], boarded_at: k[:boarded_at], alighted_at: k[:alighted_at] }
            end
          end
        end
      end.first(6)
    end

    private

    def sites = @user.limit_to_sites(@client.sites, :id).order(:name).map { { id: it.id, name: it.name, lat: it.lat&.to_f, lng: it.lng&.to_f } }

    def activities
      # School sessions count the rows the list shows, so the pill and the list always agree.
      list = SCHOOL.filter_map do |k|
        states = school_rows(k).pluck(:state)
        activity(k, states) if states.any?
      end
      %w[bookings shuttles].each do |k|
        runs = trip_runs.where(trip: { kind: k == "shuttles" ? "corporate_shuttle" : Trip.kinds.keys - %w[corporate_shuttle] })
                        .includes(:stop_events).to_a
        list << activity(k, runs.map { RunState.call(it, @now) }) if runs.any?
      end
      list
    end

    def activity(key, states)
      { key:, label: ACTIVITIES.fetch(key), count: states.size, on_road: states.count { RunState.on_road?(it) }, next: states.include?("scheduled") }
    end

    def runs_for(key)
      return school_rows(key) if SCHOOL.include?(key)

      kinds = key == "shuttles" ? "corporate_shuttle" : Trip.kinds.keys - %w[corporate_shuttle]
      trip_runs.where(trip: { kind: kinds }).includes(*INCLUDES).chronological.map { trip_row(it) }
    end

    # The client's own runs today: trips on the sites the person covers (the trip's site or a stop's); Members see
    # one-off trips only from their own bookings.
    def trip_runs
      trips = Trip.kept.where(client_id: @client.id)
      ids = site_ids
      trips = trips.where(client_site_id: ids).or(trips.where(id: TripStop.where(client_site_id: ids).select(:trip_id))) if ids
      unless @user.can?(:see_all)
        own = Trip.where(booking_trip_id: BookingTrip.joins(:booking).where(bookings: { created_by_client_user_id: @user.id }).select(:id))
        trips = trips.where(kind: "corporate_shuttle").or(trips.where(id: own.select(:id)))
      end
      TripOccurrence.visible.where(date: @today, trip_id: trips.select(:id)).where.not(status: "cancelled").joins(:trip)
    end

    # The site ids in view: the site picked, else the ones the person covers (nil = every site).
    def site_ids = @site ? [ @site.id ] : (@user.all_sites? ? nil : @user.picked_site_ids)

    # The trip's own site, else the first stop site in view (a shuttle's own site comes first).
    def run_site(trip)
      ids = site_ids
      site = ([ trip.client_site ] + trip.stops.map(&:client_site)).compact.find { ids.nil? || ids.include?(it.id) }
      site&.slice(:id, :name)
    end

    # Bookings and Shuttles wording of the prototype: "Ad Hoc / Charter, Two Way", "Two Way, return", "Shuttle, morning".
    def kind_label(o)
      trip = o.trip
      return o.trip_run&.direction == 2 ? "Shuttle, evening" : "Shuttle, morning" if trip.corporate_shuttle?
      return "Two Way, return" if trip.is_return

      trip.booking_trip&.kind_name || trip.kind_name
    end

    def trip_row(o)
      state = RunState.call(o, @now)
      planned = Occurrences::Stops.planned(o)
      events = o.stop_events.index_by(&:position)
      nxt = planned.find { !(events[it[:position]]&.departed_at || events[it[:position]]&.skipped) }
      live = RunState.on_road?(state) && o.vehicle&.live_position
      { id: o.id, date: o.date, kind: o.kind, kind_label: kind_label(o), title: o.trip.title, label: o.trip_label, site: run_site(o.trip),
        starts_at: o.starts_at, ends_at: o.ends_at, state:, state_label: RunState::LABELS.fetch(state),
        booking: o.trip.booking_trip && { id: o.trip.booking_trip.booking_id, number: o.trip.booking_trip.booking.number },
        bus: o.vehicle && { plate: o.vehicle.plate, model: [ o.vehicle.make, o.vehicle.model ].compact.join(" ").presence, seats: o.vehicle.seats },
        driver: o.decorate.driver_info&.slice(:name),
        next_stop: ({ name: nxt[:name], planned_at: LiveMap.at_minute(o, nxt[:planned_minute]), eta_at: eta(live, nxt) } if nxt && state != "ended"),
        position: live ? { lat: live.lat.to_f, lng: live.lng.to_f, speed_kmh: live.speed_kmh&.round, heading: live.heading, recorded_at: live.recorded_at } : nil,
        line: planned.filter_map { [ it[:lat].to_f, it[:lng].to_f ] if it[:lat] && it[:lng] } }
    end

    def stops(o)
      events = o.stop_events.index_by(&:position)
      Occurrences::Stops.planned(o).map do |s|
        e = events[s[:position]]
        { position: s[:position], name: s[:name], use: s[:use], planned_at: LiveMap.at_minute(o, s[:planned_minute]), lat: s[:lat]&.to_f, lng: s[:lng]&.to_f,
          arrived_at: e&.arrived_at, departed_at: e&.departed_at, skipped: e&.skipped || false }
      end
    end

    def eta(live, stop)
      return unless live && stop[:lat] && stop[:lng]

      @now + LiveMap.eta_minutes([ live.lat.to_f, live.lng.to_f ], [ stop[:lat].to_f, stop[:lng].to_f ]).minutes
    end

    # Schools linked to the client (everyone) or to the sites the person covers (or the site picked).
    def schools
      @schools ||= begin
        sites = @user.limit_to_sites(@client.sites.where.not(school_id: nil), :id)
        sites = sites.where(id: @site.id) if @site
        ids = ([ (@client.school&.id unless @site) ] + sites.pluck(:school_id)).compact.uniq
        School.where(id: ids).order(:name).to_a
      end
    end

    def school_rows(session)
      @school_rows ||= {}
      @school_rows[session] ||= schools.flat_map do |school|
        board = SchoolLive::Board.new(school, @today, session:, now: @now).call
        next [] unless board[:session] == session

        board[:rows].map do |r|
          state = school_state(r.dig(:status, :key))
          r.merge(id: r[:occurrence_id], kind: "school_bus", kind_label: SCHOOL_KINDS.fetch(session), title: "#{school.name} #{r[:label]}",
                  school: { id: school.id, name: school.name }, bus: r[:plate] && { plate: r[:plate] }, state:, state_label: RunState::LABELS.fetch(state))
        end
      end
    end

    # A School Bus run has no On the way: it is Scheduled until it starts, Started on the road, Ended once it arrived.
    def school_state(status_key) = { "arrived" => "ended", "not_started" => "scheduled" }.fetch(status_key, "started")

    # The Live Ops run detail with the list row's fields; students (not riders) at each stop; the bus only while it runs.
    def school_run(school, occ)
      session = occ.school_route.plan.session
      d = SchoolLive::Board.new(school, @today, session:, now: @now).route(occ.id)
      state = school_state(d.dig(:status, :key))
      d.merge(id: d[:occurrence_id], kind: "school_bus", kind_label: SCHOOL_KINDS.fetch(session), title: "#{school.name} #{d[:label]}",
              school: { id: school.id, name: school.name }, bus: d.dig(:bus, :plate) ? d[:bus] : nil, state:, state_label: RunState::LABELS.fetch(state),
              position: (d[:position] if state == "started"), stops: d[:stops].map { |s| s.except(:riders).merge(students: s[:riders]) })
    end
  end
end
