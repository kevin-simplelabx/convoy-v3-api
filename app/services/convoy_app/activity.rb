# Convoy App › Activity: every trip of the person across School Bus, Shuttles and Bookings in one list (HTML acts):
#   now       under way (a bus on the road for it)
#   upcoming  not under way and not over, oldest first
#   past      over, newest first, the last PAST rows only
# School Bus: each riding child × leg (pick-up / drop-off) on the days a run exists from DAYS_BACK ago to DAYS_AHEAD ahead (no
# virtual runs), Bus Not Required shown as "Not required". Shuttles: the usual timing of each employer over the same days.
# Bookings: one row per booking trip (declined ones left out) from BOOKINGS_BACK days ago, every future one. Each company's
# data is read inside that company and its time zone. service: school | shuttle | booking narrows the list.
#   Activity.call(account:, service: nil, now:)
module ConvoyApp
  class Activity < ApplicationService
    SERVICES = %w[school shuttle booking].freeze
    DAYS_BACK = 14
    DAYS_AHEAD = 7
    BOOKINGS_BACK = 30
    PAST = 8
    STATE_BADGES = { "ended" => [ "Completed", "neutral" ], "started" => [ "Started", "warning" ], "on_the_way" => [ "On the way", "warning" ],
                     "scheduled" => [ "Scheduled", "neutral" ] }.freeze

    def initialize(account:, service: nil, now: Time.current)
      @account = account
      @service = SERVICES.include?(service.to_s) ? service.to_s : nil
      @now = now
    end

    def call
      rows = { "school" => school_rows, "shuttle" => shuttle_rows, "booking" => booking_rows }
      services = rows.select { |_, list| list.any? }.keys
      list = @service ? rows[@service] : rows.values.flatten
      now, rest = list.partition { it[:live] }
      past, upcoming = rest.partition { it[:done] }
      { services:, service: @service, now: sort(now), upcoming: sort(upcoming), past: sort(past).reverse.first(PAST) }
    end

    private

    def sort(list) = list.sort_by { [ it[:date], it[:time].to_s, it[:title] ] }

    def household = @household ||= HouseholdMember.active.joins(:household).merge(Household.kept).find_by(app_account_id: @account.id)&.household

    def row(service, date, time, title, sub, badge, tone, live:, done:, open:)
      { service:, date:, time:, title:, sub:, badge:, tone:, live:, done:, open: }
    end

    # School Bus: the children's legs, inside each company.
    def school_rows
      return [] unless household

      Parents::RiderRequest.kids(household).flat_map do |kid|
        Parents.within(kid.company) { kid_rows(kid) }
      end
    end

    def kid_rows(kid)
      today = Time.zone.today
      range = (today - DAYS_BACK)..(today + DAYS_AHEAD)
      rid = kid.rider.rid
      places = SchoolRouteRider.joins(school_route: :plan).where(rid:, school_plans: { school_id: kid.school.id }).includes(:stop).index_by(&:school_route_id)
      return [] if places.empty?

      runs = TripOccurrence.where(school_route_id: places.keys, date: range).visible.includes(:vehicle, :stop_events, school_route: :plan).order(:date, :starts_at).to_a
      off = SchoolRiderAbsence.where(school: kid.school, rid:, date: range).index_by(&:date)
      dep = kid.dependant
      runs.map do |occ|
        session = occ.school_route.plan.session
        am = session == "am"
        stop = places[occ.school_route_id].stop
        absent = off[occ.date]&.covers?(session)
        state = Portal::RunState.call(occ, @now)
        label, tone = if absent then [ "Not required", "neutral" ]
        elsif occ.cancelled? then [ "Cancelled", "danger" ]
        else STATE_BADGES[state]
        end
        live = Portal::RunState.on_road?(state) && !absent && !occ.cancelled?
        plate = occ.vehicle&.plate
        title = am ? "Pick-up · #{dep.first_name}" : "Drop-off · #{dep.first_name}"
        sub = am ? [ stop.name, plate ] : [ "Leaves school #{occ.school_route.start_time_hm}", plate ]
        open = if am && live then { kind: "live", bus: "#{occ.school_route_id}-#{occ.date}" }
        else { kind: "bus_info", dependant_id: dep.id, session: }
        end
        row("school", occ.date, am ? stop.scheduled_time_hm : occ.school_route.start_time_hm, title, sub.compact.join(" · "), label, tone,
            live:, done: !live && (state == "ended" || absent || occ.cancelled? || occ.date < today), open:)
      end
    end

    # Shuttles: the usual timing at each employer.
    def shuttle_rows
      Shuttles.employers(@account).flat_map do |employer|
        Shuttles.within(employer) { usual_rows(employer) }
      end
    end

    def usual_rows(employer)
      usual = Shuttles::UsualOf.for(@account, employer.client)
      return [] unless usual.present?

      today = Time.zone.today
      trip = Shuttles.trips(employer, today).find_by(id: usual.trip_id) or return []
      run = trip.runs.find { it.id == usual.run_id } or return []
      stop = trip.stops_in(run.direction).find { it.id == usual.stop_id }
      occs = TripOccurrence.where(trip_id: trip.id, trip_run_id: run.id, date: (today - DAYS_BACK)..(today + DAYS_AHEAD)).visible
                           .includes(:vehicle, :replacement, :stop_events).order(:date, :slot_no).to_a
      occs.group_by(&:date).map do |date, list|
        changes = list.map { Shuttles::Change.of(it, trip:, regular_vehicle_id: Occurrences::Regular.vehicle_id(trip, run, it.slot_no, date)) }
        worst = Shuttles::Change.worst(changes)
        states = list.reject(&:cancelled?).map { Portal::RunState.call(it, @now) }
        live = states.any? { Portal::RunState.on_road?(it) }
        ended = states.empty? || states.all?("ended")
        label, tone = case worst
        when "cancelled" then [ "Cancelled", "danger" ]
        when "bus" then [ "Different bus", "warning" ]
        when "driver" then [ "Relief driver", "warning" ]
        else STATE_BADGES[live ? (states.include?("started") ? "started" : "on_the_way") : ended ? "ended" : "scheduled"]
        end
        plates = list.reject(&:cancelled?).filter_map { it.vehicle&.plate }.uniq.join(", ").presence
        row("shuttle", date, list.first.start_time_hm, "#{trip.title} · #{Shuttles::DIRECTIONS[run.direction]}",
            [ stop&.name_in(run.direction), plates ].compact.join(" · "), label, tone, live:, done: !live && (ended || date < today),
            open: { kind: "shuttle_route", employer_id: employer.id, route_id: trip.id })
      end
    end

    # Bookings: every booking account's trips.
    def booking_rows
      Bookings.accounts(@account).flat_map do |acc|
        Bookings.within(acc) { account_rows(acc) }
      end
    end

    def account_rows(acc)
      today = Time.zone.today
      bookings = Bookings.visible(acc).where(id: BookingDay.where(date: (today - BOOKINGS_BACK)..).select(:booking_id))
                         .includes(*Bookings::Present::INCLUDES).to_a
      return [] if bookings.empty?

      runs = Bookings::Runs.load(bookings, now: @now)
      bookings.flat_map do |b|
        b.days.flat_map(&:trips).reject(&:rejected?).select { it.date >= today - BOOKINGS_BACK }.map do |t|
          st = Bookings::Status.trip(t, b, runs, today)
          last = t.out_points.last&.name
          buses = t.vehicles_count
          row("booking", t.date, t.start_time_hm, [ b.title || b.number, last ].compact.join(" · "),
              [ t.kind_name, "#{buses} #{buses == 1 ? 'bus' : 'buses'}", acc.tc ].join(" · "), Bookings::Status::TRIP_LABELS[st], Bookings::Status::TRIP_TONES[st],
              live: st == "live", done: %w[done cancelled].include?(st) || t.date < today,
              open: st == "live" ? { kind: "track", booking_id: b.id } : { kind: "booking", booking_id: b.id })
        end
      end
    end
  end
end
