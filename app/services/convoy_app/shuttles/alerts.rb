# The shuttle alerts of the Convoy App, written into the inbox (`app_notifications`) by a recurring job (ShuttleAlertsJob, every
# 5 minutes). Only change alerts exist, as in the HTML; Reminder, Running Late and Notices are saved settings only.
#   Bus change     1 hour before the bus reaches the rider's stop, with the bus as it stands then; once more at once if it
#                  changes again (the vehicle is in the key). A change made less than an hour before alerts at once. Never on a
#                  No Fixed Bus route, never for a relief driver alone.
#   Cancelled      at once (runs of the next 14 days), with the next bus.
#   No / changed   the day before at 12:00 (public holiday, the client's day off, calendar shift), once per change.
# For the timings and weekdays ticked in the route's Alert Settings (the default for the usual route), links that are accepted
# and not paused, while Pause Alerts is not set, never for runs that have ended. Each alert has a dedupe key, so a run of the job
# never repeats one.
module ConvoyApp
  module Shuttles
    class Alerts < ApplicationService
      BUS_LEAD = 1.hour
      DAY_BEFORE_AT = 12.hours

      def self.key(kind, occ)
        base = [ occ.trip_id, occ.date, occ.trip_run_id, occ.slot_no, occ.part ].join(":")
        kind == "bus" ? "shuttle:bus:#{base}:#{occ.vehicle_id}" : "shuttle:#{kind}:#{base}"
      end

      def self.day_key(trip_id, date, signature) = "shuttle:day:#{trip_id}:#{date}:#{signature}"

      def initialize(now: Time.current)
        @now = now
      end

      # How many alerts were written.
      def call
        riders = ActsAsTenant.without_tenant { ClientRider.where(status: "accepted").to_a }
        return 0 if riders.empty?

        accounts = AppAccount.where(id: riders.map(&:app_account_id).uniq).includes(:identities).index_by(&:id)
        Company.active.where(id: riders.map(&:company_id).uniq).sum do |company|
          Parents.within(company) { company_alerts(company, riders.select { it.company_id == company.id }, accounts) }
        end
      end

      private

      def company_alerts(company, riders, accounts)
        today = Time.zone.today
        riders = riders.select { live?(accounts[it.app_account_id], it, today) }
        return 0 if riders.empty?

        ids = riders.map(&:app_account_id)
        saved = ShuttleAlertSetting.includes(:setting_runs).where(app_account_id: ids).index_by { [ it.app_account_id, it.trip_id ] }
        usuals = ShuttleUsual.includes(:trip_run).where(app_account_id: ids).index_by { [ it.app_account_id, it.client_id ] }
        @bells = ShuttleStopBell.where(app_account_id: ids, on: true).pluck(:app_account_id, :trip_id, :direction, :trip_stop_id).group_by { it.first(3) }
        trips = Shuttles.trips_of(riders.map(&:client_id).uniq, today).to_a.group_by(&:client_id)
        @days = {}
        rows = riders.flat_map do |rider|
          usual = UsualOf.new(usuals[[ rider.app_account_id, rider.client_id ]])
          (trips[rider.client_id] || []).flat_map do |trip|
            setting = AlertSettings.effective(accounts[rider.app_account_id], trip, usual, saved: saved[[ rider.app_account_id, trip.id ]])
            setting.enabled ? rider_alerts(rider, company, trip, setting, usual, today) : []
          end
        end
        return 0 if rows.empty?

        ConvoyApp::Alerts.write(rows)
      end

      def live?(account, rider, today)
        identity = account.identities.find { it.email? && it.work? && it.value == rider.matched_email }
        identity && !identity.links_paused?(today) && AlertSettings.paused_until(account, today:).nil?
      end

      def days_of(trip, today) = @days[trip.id] ||= Days.new(trip, today, today + STRIP_DAYS - 1)

      def rider_alerts(rider, company, trip, setting, usual, today)
        days = days_of(trip, today)
        ctx = { rider:, company:, trip:, setting:, usual:, days:, today: }
        rows = []
        rows += cancelled(**ctx) if setting.bus_change
        rows += bus_changes(**ctx) if setting.bus_change
        rows += service_days(**ctx) if setting.service_days
        rows
      end

      # The timings the rider ticked, on weekdays they ride, for a date.
      def ticked(trip, setting, days, date)
        return [] unless setting.weekdays.include?(date.wday)

        days.runs_on(date).select { setting.run_ids.include?(it.trip_run_id) }.group_by(&:trip_run_id).map { |run_id, occs| [ trip.runs.find { it.id == run_id }, occs ] }
      end

      def cancelled(rider:, company:, trip:, setting:, usual:, days:, today:)
        (today...(today + STRIP_DAYS)).flat_map do |date|
          ticked(trip, setting, days, date).filter_map do |run, occs|
            next unless occs.all?(&:cancelled?) && occs.first.ends_at > @now

            first = occs.first
            row(rider, "shuttle_cancelled", "Shuttle cancelled", "#{trip.title} #{first.start_time_hm} on #{day_name(date, today)} was cancelled by #{company.name}.#{next_bus_text(days, trip, run, date)}",
                key: self.class.key("cancelled", first), trip:, occ: first, company:)
          end
        end
      end

      def bus_changes(rider:, company:, trip:, setting:, usual:, days:, today:)
        (today..(today + 1)).flat_map do |date|
          ticked(trip, setting, days, date).flat_map do |run, occs|
            stop = rider_stop(rider, trip, run.direction, usual, occs.first) or next []
            occs.filter_map do |occ|
              change = days.change(occ)
              next unless change&.dig(:kind) == "bus" && occ.ends_at > @now

              alert_at = LiveMap.at_minute(occ, stop[:minute]) - BUS_LEAD
              next if @now < alert_at

              regular = Vehicle.find_by(id: change[:regular_vehicle_id])
              body = "Look for #{occ.vehicle.plate} on the #{occ.start_time_hm} #{trip.title} shuttle #{day_name(date, today)}#{regular ? " instead of #{regular.plate}" : ''}. It reaches #{stop[:name]} at #{Clock.hm(stop[:minute])}."
              row(rider, "shuttle_bus_change", "Different bus", body, key: self.class.key("bus", occ), trip:, occ:, company:)
            end
          end
        end
      end

      def service_days(rider:, company:, trip:, setting:, usual:, days:, today:)
        tomorrow = today + 1
        return [] if @now < today.in_time_zone + DAY_BEFORE_AT || !setting.weekdays.include?(tomorrow.wday)

        day = days.day(tomorrow)
        runs = trip.runs.select { setting.run_ids.include?(it.id) }
        return [] if runs.empty?

        if day.state == "no_service" && days.occurrences[tomorrow]&.any?(&:skipped?)
          text = "No shuttle on #{trip.title} tomorrow (#{day.reason})."
          text += " Service resumes #{day.resumes_on.strftime('%a %-d %b')}." if day.resumes_on
          [ row(rider, "shuttle_service_day", "No service tomorrow", text, key: self.class.day_key(trip.id, tomorrow, "off"), trip:, occ: nil, company:,
                       until_at: tomorrow.end_of_day) ]
        elsif day.state == "changed"
          shifted = days.runs_on(tomorrow).select { |o| setting.run_ids.include?(o.trip_run_id) && o.start_time != trip.runs.find { |r| r.id == o.trip_run_id }.start_time }
          return [] if shifted.empty?

          times = shifted.map(&:start_time_hm).uniq.join(", ")
          [ row(rider, "shuttle_service_day", "Changed times tomorrow", "#{trip.title} runs at #{times} tomorrow.", key: self.class.day_key(trip.id, tomorrow, times), trip:, occ: shifted.first, company:,
                       until_at: tomorrow.end_of_day) ]
        else
          []
        end
      end

      # The usual boarding stop on this route and direction, else the first belled stop, else the first boarding stop.
      def rider_stop(rider, trip, direction, usual, occ)
        planned = Occurrences::Stops.planned(occ)
        stops = trip.stops_in(direction)
        belled = (@bells[[ rider.app_account_id, trip.id, direction ]] || []).map(&:last)
        index = stops.index { usual.stop_in?(trip, direction) && it.id == usual.stop_id } || stops.index { belled.include?(it.id) } ||
                planned.index { it[:use].in?(%w[pu both]) }
        index && planned[index][:planned_minute] && { name: planned[index][:name], minute: planned[index][:planned_minute] }
      end

      def next_bus_text(days, trip, run, date)
        direction_of = ->(o) { trip.runs.find { |r| r.id == o.trip_run_id }.direction }
        later = days.runs_on(date).select { |o| o.trip_run_id != run.id && !o.cancelled? && direction_of.(o) == run.direction && o.start_time > run.start_time }
        nxt = later.min_by(&:start_time)
        nxt ? " Next bus #{nxt.start_time_hm} from #{trip.stops_in(run.direction).first.name_in(run.direction)}." : " No more buses that #{run.direction == 1 ? 'morning' : 'evening'}."
      end

      def day_name(date, today) = date == today ? "today" : (date == today + 1 ? "tomorrow" : date.strftime("%a %-d %b"))

      # Tap opens the route; the alert stays on Home until the run ends (a day alert: until the end of that day).
      def row(rider, kind, title, body, key:, trip:, occ:, company:, until_at: nil)
        { app_account_id: rider.app_account_id, company_id: company.id, kind:, title:, body:, trip_id: trip.id, occurrence_id: occ&.id,
          occurrence_date: occ&.date, dedupe_key: key, target: "shuttle_route", target_id: rider.id, banner_until: until_at || occ&.ends_at }
      end
    end
  end
end
