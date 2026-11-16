# Convoy App › Home (HTML hm): greeting, invitations to answer (Family invites, organisations that found the person by work
# email), notice banners (inbox rows with banner_until ahead, not dismissed: school / shuttle notices, late, different bus,
# shuttle changes; the newest per run and kind), Up Next cards (bookings of the person's school / company accounts first,
# then the Family's morning buses, the Family's next step, each employer's usual shuttle, then Personal bookings), the
# service tiles with badges, Get Started for a person with nothing yet, and the unread Alerts count. The School Bus section
# under Up Next is GET /app/school. Each company's data is read inside that company.
module ConvoyApp
  class Home < ApplicationService
    BANNERS = 10
    ACTIONS = { "live" => "Track the Bus", "school_calendar" => "See School Calendar", "shuttle_route" => "Open", "booking" => "Open" }.freeze

    def initialize(account:, now: Time.current)
      @account = account
      @now = now
    end

    def call
      Links::Match.call(account: @account)
      employers = Shuttles.employers(@account)
      bookings = upcoming_bookings
      invites = invitations
      up = up_next(employers, bookings)
      fresh = member.nil? && employers.empty? && bookings.empty?
      { greeting: greeting(fresh), invitations: invites, banners: banners, up_next: up, tiles: tiles(employers, bookings),
        get_started: fresh, badges: { alerts: @account.notifications.unread.count } }
    end

    private

    def member
      return @member if defined?(@member)

      @member = HouseholdMember.active.joins(:household).merge(Household.kept).includes(household: :dependants).find_by(app_account_id: @account.id)
    end

    def household = member&.household

    def greeting(fresh)
      hour = @now.in_time_zone.hour
      part = if hour < 12 then "morning"
      elsif hour < 18 then "afternoon"
      else "evening"
      end
      first = @account.first_name
      { first_name: first, part_of_day: part, text: fresh && household.nil? ? "Welcome, #{first}" : "Good #{part}, #{first}" }
    end

    # Family invites to this person and organisations that found their work email (Accept / Not Me on Home).
    def invitations
      family = HouseholdMember.invitations_for(@account).includes(:household, :invited_by).order(:id).select { it.household.kept? }.map do |m|
        { id: m.id, family: m.household.name, invited_by: m.invited_by&.display_name, relationship: m.relationship, invited_at: m.updated_at }
      end
      orgs = OrganisationLinks.call(account: @account).select { it[:status] == "invited" }
      { family:, organisations: orgs }
    end

    # The newest banner per run (or notice) and kind.
    def banners
      rows = @account.notifications.banners_at(@now).includes(:company).newest.limit(BANNERS * 3).to_a
      rows.uniq { [ it.kind, it.occurrence_id || it.notice_id || it.id ] }.first(BANNERS).map do |n|
        { id: n.id, kind: n.kind, icon: n.icon, tone: n.tone, title: n.title, body: n.body, sender: n.company&.name, at: n.created_at,
          until: n.banner_until, action: n.target && { label: ACTIONS[n.target] || "Open", target: n.target, target_id: n.target_id, trip_id: n.trip_id } }
      end
    end

    # Open bookings of every account (a trip still to run), each as its list card with the account kind.
    def upcoming_bookings
      @upcoming_bookings ||= Bookings.accounts(@account).flat_map do |acc|
        Bookings.within(acc) do
          today = Time.zone.today
          open = BookingTrip.joins(:day).where(booking_days: { date: today.. }).where.not(status: %w[cancelled rejected]).select(:booking_id)
          list = Bookings.visible(acc).where(id: open).includes(*Bookings::Present::INCLUDES).to_a
          runs = Bookings::Runs.load(list, now: @now)
          list.map { |b| [ acc, Bookings::Present.new(acc, b, runs, now: @now).card, b, runs ] }
        end
      end.sort_by { |_, c, _, _| [ c[:first_date], c[:id] ] }
    end

    def up_next(employers, bookings)
      links, personal = bookings.partition { |acc, *| acc.link? }
      cards = []
      cards << booking_card(*links.first) if links.any?
      cards << no_booking_card(Bookings.accounts(@account).find(&:link?)) if links.empty? && Bookings.accounts(@account).any?(&:link?)
      cards.concat(school_cards)
      cards.concat(employers.map { shuttle_card(it) })
      cards << booking_card(*personal.first) if personal.any?
      cards.compact
    end

    def booking_card(acc, card, booking, runs)
      Bookings.within(acc) do
        trip = booking.days.first.trips.reject { it.cancelled? || it.rejected? }.min_by(&:start_time) || booking.days.first.trips.first
        today = trip.date == Time.zone.today
        st = Bookings::Status.trip(trip, booking, runs)
        out = runs.out(trip)
        here = out.count { Bookings::Track.state(it, @now)[:state] == "here" }
        badge = today && st == "live" ? (here == out.size ? "All buses here" : "#{here} of #{out.size} buses here") : card[:status_label]
        n = trip.vehicles_count
        { kind: "booking", icon: "directions_bus", label: "Booking · #{acc.tc} · #{booking.number}", badge:, tone: card[:tone],
          depart: { time: trip.start_time_hm, text: "#{today ? 'Depart today' : "Depart #{trip.date.strftime('%a %-d %b')}"} · #{trip.out_points.first&.name}" },
          arrive: { time: nil, text: "Arrive · #{trip.out_points.last&.name}" },
          foot: [ card[:title], "#{n} #{n == 1 ? 'bus' : 'buses'}", "#{trip.pax.to_i + trip.adults.to_i} pax", (trip.return_time_hm && "return #{trip.return_time_hm}") ].compact.join(" · "),
          open: { kind: st == "live" ? "track" : "booking", booking_id: booking.id } }
      end
    end

    def no_booking_card(acc)
      { kind: "booking_none", icon: "directions_bus", label: "Bookings · #{acc.org}", title: "No upcoming bookings",
        sub: "Book buses for excursions, learning journeys, camps and events. Your approver signs off, then #{acc.tc} confirms.",
        foot: "New Booking", open: { kind: "new_booking", account: acc.key } }
    end

    # The Family's morning buses, else the Family's next step (a child waiting for a bus, or no child yet).
    def school_cards
      return [] unless household

      buses = Parents::MorningBuses.call(household)
      return buses.map { bus_card(it) } if buses.any?

      kids = household.dependants.to_a
      if kids.empty?
        return [ { kind: "school_message", icon: "school", label: "School Bus · #{household.name}", title: "Add your children",
                   sub: "Then apply for the bus when their school opens its application window.", foot: "Add a Child", open: { kind: "add_child" } } ]
      end

      waiting = Parents::Page.new(member).call[:children].find { it[:action] }
      return [] unless waiting

      [ { kind: "school_message", icon: "school", label: "School Bus · #{waiting.dig(:company, :name) || 'Application'}", badge: waiting.dig(:badge, :label),
          tone: waiting.dig(:badge, :tone), title: "#{waiting[:name]} · #{waiting.dig(:school, :name)}", sub: waiting[:line], who: [ { name: waiting[:name] } ],
          foot: waiting.dig(:action, :label) || "School Bus", open: waiting[:action] } ]
    end

    def bus_card(bus)
      co = bus.company.decorate.display_name
      day = bus.today? ? nil : bus.date.strftime("%a %-d %b")
      if bus.route.nil?
        names = bus.no_route.map(&:first_name).join(" and ")
        return { kind: "school_message", icon: "school", label: "School Bus · #{co}", title: "#{names} has no morning route yet",
                 sub: "#{co} adds the stop and times once the route is planned.", foot: "School Bus", open: { kind: "school" } }
      end
      if bus.kids.empty?
        return { kind: "school_message", icon: "school", label: "School Bus · #{co}", title: "No pick-up #{day ? "on #{day}" : 'this morning'}",
                 sub: "#{bus.off.map { it[:dependant].first_name }.join(' and ')} marked not required.", foot: "School Bus", open: { kind: "school" } }
      end

      Parents.within(bus.company) do
        live = Parents::Live::Detail.new(bus, @now).call[:bus]
        first = bus.kids.first
        off = bus.off.map { it[:dependant].first_name }
        { kind: "school_bus", icon: "school", label: "School Bus · #{co} · #{bus.route.title}", badge: day || live[:status][:label], tone: live[:status][:tone],
          changed: live[:change].present?, late_minutes: live[:late_minutes],
          depart: { time: first[:stop]&.scheduled_time_hm, text: "Pick-up · #{first[:stop]&.name}" },
          arrive: { time: bus.route.end_time_hm, text: "Arrive · #{bus.school.name}" }, who: bus.kids.map { { name: it[:dependant].name } },
          foot: [ bus.names.join(" and "), live.dig(:vehicle, :plate), (off.any? ? "#{off.join(', ')} not required" : nil) ].compact.join(" · "),
          open: { kind: "live", bus: bus.key } }
      end
    end

    # The usual shuttle's next run today (or "Pick your usual shuttle").
    def shuttle_card(employer)
      co = employer.client.name.delete_suffix(" Pte Ltd")
      Shuttles.within(employer) do
        usual = Shuttles::UsualOf.for(@account, employer.client)
        today = Time.zone.today
        trip = usual.present? && Shuttles.trips(employer, today).find_by(id: usual.trip_id)
        run = trip && trip.runs.find { it.id == usual.run_id }
        unless run
          next { kind: "shuttle_message", icon: "commute", label: "Shuttle · #{co}", title: "Pick your usual shuttle",
                 sub: "Choose your route, timing and stop once. Up Next then shows your next run.", foot: "Choose My Usual Shuttle",
                 open: { kind: "shuttle_usual", employer_id: employer.id } }
        end

        occs = TripOccurrence.where(trip_id: trip.id, trip_run_id: run.id, date: today).visible.includes(:vehicle, :replacement, :stop_events).order(:slot_no).to_a
        changes = occs.map { Shuttles::Change.of(it, trip:, regular_vehicle_id: Occurrences::Regular.vehicle_id(trip, run, it.slot_no, today)) }
        worst = Shuttles::Change.worst(changes)
        states = occs.reject(&:cancelled?).map { Portal::RunState.call(it, @now) }
        live = states.any? { Portal::RunState.on_road?(it) }
        badge = { "cancelled" => "Cancelled today", "bus" => "Different bus today", "driver" => "Relief driver today" }[worst] ||
                (live ? "On the way" : (states.any? && states.all?("ended") ? "Completed" : "Scheduled"))
        stops = trip.stops_in(run.direction)
        board = stops.find { it.id == usual.stop_id } || stops.first
        plate = occs.reject(&:cancelled?).first&.vehicle&.plate
        { kind: "shuttle", icon: "commute", label: "Shuttle · #{co} · #{trip.title}", badge:, tone: worst == "cancelled" ? "danger" : (worst || live ? "warning" : "neutral"),
          depart: { time: run.start_time_hm, text: "Board · #{board&.name_in(run.direction)}" },
          arrive: { time: nil, text: "Alight · #{stops.last&.name_in(run.direction)}" },
          foot: [ Shuttles::DIRECTIONS[run.direction], plate ].compact.join(" · "),
          open: { kind: "shuttle_route", employer_id: employer.id, route_id: trip.id } }
      end
    end

    def tiles(employers, bookings)
      kids = household&.dependants.to_a
      riding = household ? ConvoyApp::Households::BusService.facts(household).count { |_, f| f[:riding] } : 0
      due = member && Parents.billing?(member) ? Fees.outstanding(household).size : 0
      changed = bookings.count { |_, card, *| card[:status] == "changed" }
      school_caption = if riding.positive? then "#{riding} #{riding == 1 ? 'child' : 'children'}"
      elsif household then kids.any? ? "#{kids.size} #{kids.size == 1 ? 'child' : 'children'}" : "Add children"
      else "Set up"
      end
      [ { key: "school_bus", label: "School Bus", caption: school_caption, on: household.present?, badge: due.positive? ? due : nil },
        { key: "shuttles", label: "Shuttles", caption: employers.any? ? employers.map { it.json[:mark] }.join(" · ") : "By employer", on: employers.any?, badge: nil },
        { key: "bookings", label: "Bookings", caption: bookings.any? ? "#{bookings.size} upcoming" : "Book a bus", on: true, badge: changed.positive? ? changed : nil },
        { key: "discover", label: "Discover", caption: "Coming soon", on: false, badge: nil } ]
    end
  end
end
