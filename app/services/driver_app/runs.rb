# A driver's runs in the Convoy Driver app: the company's runs (trip_occurrences, within the horizon) the membership
# drives, plus those a replacement took from them (shown as Replaced). Status and kind in the app's words
# (decided 26/10/2026): Scheduled, On the Way, Started, Ended, Skipped, Replaced, Cancelled.
module DriverApp
  module Runs
    # Not shown: removed by a change of plan, or a day the calendar skips.
    HIDDEN = %w[removed skipped].freeze
    KINDS = { "school_route" => "school", "school_run" => "school_run", "corporate_shuttle" => "shuttle", "disposal" => "disposal",
              "airport_transfer" => "airport", "ad_hoc" => "adhoc" }.freeze
    KIND_LABELS = { "school" => "School Bus", "school_run" => "School Run", "shuttle" => "Shuttle", "disposal" => "Disposal",
                    "airport" => "Airport Transfer", "adhoc" => "Ad Hoc" }.freeze
    STATUS_LABELS = { "scheduled" => "Scheduled", "on_the_way" => "On the Way", "started" => "Started", "ended" => "Ended",
                      "replaced" => "Replaced", "skipped" => "Skipped", "cancelled" => "Cancelled" }.freeze
    INCLUDES = [ :client, :vehicle, :original_vehicle, :driver, :operator_driver, :stop_events, :replacement, { trip_run: :times },
                 { trip: [ :client, { stops: :photos }, :route_vias ] }, { school_route: [ { stops: :riders }, { plan: :school } ] } ].freeze

    DETAIL_INCLUDES = [ *INCLUDES, :passenger_marks, :driver_report, { disposal: %i[runs extensions] },
                        { trip: [ :client, :route_vias, :attachments, { stops: :photos }, { standby: :photos }, { booking_trip: { booking: :days } } ] } ].freeze

    module_function

    def scope(member)
      own, was = member.is_a?(OperatorDriver) ? %i[operator_driver_id original_operator_driver_id] : %i[driver_id original_driver_id]
      TripOccurrence.where.not(status: HIDDEN).where(own => member.id).or(TripOccurrence.where.not(status: HIDDEN).where(was => member.id))
    end

    # The run's record at a point (built when there is none yet).
    def event_for(occ, point)
      occ.stop_events.find { it.position == point[:position] } ||
        occ.stop_events.build(company_id: occ.company_id, position: point[:position], stop_name: point[:name], source: "driver_app")
    end

    # The run this driver has started and not ended (the trip on the road), or nil.
    def on_the_road(member, on: Date.current)
      scope(member).where(date: (on - 1)..on, ended_at: nil).where.not(started_at: nil).where.not(status: "cancelled")
                   .includes(INCLUDES).order(:started_at).to_a.reverse.find { mine?(it, member) }
    end

    def mine?(occ, member) = (member.is_a?(OperatorDriver) ? occ.operator_driver_id : occ.driver_id) == member.id

    def kind(occ) = KINDS.fetch(occ.kind, "adhoc")

    def status(occ, member)
      if occ.cancelled? then occ.driver_end == "skipped" ? "skipped" : "cancelled"
      elsif !mine?(occ, member) then "replaced"
      elsif occ.ended_at || occ.completed? then "ended"
      elsif occ.started_at then occ.stop_events.any?(&:departed_at) ? "started" : "on_the_way"
      else "scheduled"
      end
    end

    # "To School", "Outbound", "Arrival"… — the line under the route name.
    def direction(occ)
      return occ.school_route.plan.session == "am" ? "To School" : "To Home" if occ.school_route

      trip = occ.trip
      case trip.kind
      when "school_run" then trip.session == "pm" ? "To Home" : "To School"
      when "corporate_shuttle" then occ.trip_run&.direction == 2 ? "Return" : "Outbound"
      when "airport_transfer" then trip.airport_direction&.humanize
      when "disposal" then "As Directed"
      else trip.is_return? ? "Return" : "One Way"
      end
    end

    # The client as the driver sees it: the customer served, "via" the main contractor on a sub-contracted trip.
    def client(occ)
      return { name: occ.school_route.plan.school.name, via: nil } if occ.school_route

      trip = occ.trip
      if trip.subcontracted? && trip.service_for.present? then { name: trip.service_for, via: occ.client&.name }
      else { name: occ.client&.name, via: nil }
      end
    end

    # Pay multiplier from Convoy OS: own drivers only, never on a disposal.
    def trip_value(occ, member) = member.is_a?(Driver) && occ.kind != "disposal" && mine?(occ, member) ? occ.trip_value : nil

    # Attendance (names) on School Bus and School Run; a head count on shuttles that ask for one.
    def requires(occ)
      if occ.school_route || occ.trip&.school_run? then "attendance"
      elsif occ.trip&.head_count? then "count"
      end
    end
  end
end
