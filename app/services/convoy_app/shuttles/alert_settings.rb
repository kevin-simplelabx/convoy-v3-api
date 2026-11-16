# Convoy App › Alert Settings of a route (and the list on Account › Notifications › Shuttle Alerts). Defaults for a route never
# saved (the HTML): the usual route is on with the usual timing, Mon to Fri, 5 minutes, all four change types on; every other
# route is off. `effective` is what the alert job and the screens use: the saved row, else that default.
module ConvoyApp
  module Shuttles
    module AlertSettings
      Effective = Data.define(:enabled, :run_ids, :weekdays, :lead_minutes, :bus_change, :service_days, :late, :notices, :saved) do
        def json = { enabled:, run_ids:, weekdays:, lead_minutes:, notify: { bus_change:, service_days:, late:, notices: }, saved: }
      end

      module_function

      # The setting of a trip for the account (inside the employer's company). `usual` = UsualOf. saved: the row when the caller
      # loaded them in bulk (nil = none saved); left out, it is read here.
      def effective(account, trip, usual, saved: :find)
        saved = ShuttleAlertSetting.includes(:setting_runs).find_by(app_account_id: account.id, trip_id: trip.id) if saved == :find
        return from_row(saved) if saved

        mine = usual.trip_id == trip.id
        Effective.new(enabled: mine, run_ids: mine ? [ usual.run_id ] : [], weekdays: ShuttleAlertSetting::DEFAULT_WEEKDAYS, lead_minutes: 5,
                      bus_change: true, service_days: true, late: true, notices: true, saved: false)
      end

      def from_row(row)
        Effective.new(enabled: row.enabled, run_ids: row.run_ids, weekdays: row.weekdays, lead_minutes: row.lead_minutes, bus_change: row.notify_bus_change,
                      service_days: row.notify_service_days, late: row.notify_late, notices: row.notify_notices, saved: true)
      end

      # The screen of one route: every timing of the route with its tick.
      def show(account:, employer:, trip_id:)
        Shuttles.within(employer) do
          trip = Shuttles.trip!(employer, trip_id, Time.zone.today)
          usual = UsualOf.for(account, employer.client)
          { route: { id: trip.id, name: trip.title, tags: Shuttles.tags(trip) }, employer: employer.json,
            timings: Shuttles.directions(trip).flat_map { |d| trip.runs.select { it.direction == d }.sort_by(&:position).map { |r| { run_id: r.id, direction: d, name: DIRECTIONS.fetch(d), time: Shuttles.hm(r.start_time) } } },
            setting: effective(account, trip, usual).json, paused_until: paused_until(account) }
        end
      end

      # Every route of every employer the person rides with: name, employer, whether alerts are on and the summary line parts.
      def list(account:)
        employers = Shuttles.employers(account)
        routes = employers.flat_map do |employer|
          Shuttles.within(employer) do
            usual = UsualOf.for(account, employer.client)
            saved = ShuttleAlertSetting.includes(:setting_runs).where(app_account_id: account.id).index_by(&:trip_id)
            Shuttles.trips(employer, Time.zone.today).to_a.select { Shuttles.directions(it).any? }.map do |trip|
              setting = effective(account, trip, usual, saved: saved[trip.id])
              { employer: employer.json, route: { id: trip.id, name: trip.title }, **setting.json, timings: setting.run_ids.size }
            end
          end
        end
        { paused_until: paused_until(account), routes: routes.sort_by { [ it[:employer][:name].downcase, it[:route][:name].downcase ] } }
      end

      # Save: enabled, run_ids (timings), weekdays (0 Sun .. 6 Sat), lead_minutes (5/10/15), bus_change, service_days, late, notices.
      # A field left out keeps what the screen showed: the saved row, or for a route never saved the default (`effective`), so
      # the list switch ({ enabled } only) keeps the usual timing; a route that has no default timing switched on that way
      # gets every timing of the route.
      def save(account:, employer:, trip_id:, params:)
        Shuttles.within(employer) do
          trip = Shuttles.trip!(employer, trip_id, Time.zone.today)
          row = ShuttleAlertSetting.includes(:setting_runs).find_or_initialize_by(app_account_id: account.id, trip_id: trip.id)
          base = row.persisted? ? from_row(row) : effective(account, trip, UsualOf.for(account, employer.client), saved: nil)
          attrs = attributes(base, params)
          run_ids = if params.key?(:run_ids) then Array(params[:run_ids]).map(&:to_i).uniq
          elsif row.new_record? && attrs[:enabled] && base.run_ids.empty? then timing_ids(trip)
          else base.run_ids
          end
          raise ApplicationService::Error, "Pick a timing of this route" unless (run_ids - trip.runs.map(&:id)).empty?

          check!(attrs, run_ids)
          ShuttleAlertSetting.transaction do
            row.assign_attributes(attrs.merge(company_id: employer.company.id, client_id: employer.client.id))
            row.save!
            row.setting_runs.where.not(trip_run_id: run_ids).delete_all
            (run_ids - row.setting_runs.pluck(:trip_run_id)).each { row.setting_runs.create!(trip_run_id: it) }
          end
          show(account:, employer:, trip_id:)
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      # Same words as the HTML (alrSave).
      def check!(attrs, run_ids)
        return unless attrs[:enabled]

        any_change = attrs.values_at(:notify_bus_change, :notify_service_days, :notify_late, :notify_notices).any?
        if run_ids.empty? && !any_change
          raise ApplicationService::Error, "Pick a timing to be reminded for, or a change to hear about, or turn alerts off"
        end
        raise ApplicationService::Error, "Pick at least one day" if run_ids.any? && attrs[:weekdays].empty?
      end

      # The row's values: each param sent, else what `base` (Effective: saved or default) has.
      def attributes(base, params)
        flag = ->(key, current) { params.key?(key) ? ActiveModel::Type::Boolean.new.cast(params[key]) : current }
        { enabled: flag.call(:enabled, base.enabled), weekdays: params.key?(:weekdays) ? Array(params[:weekdays]).map(&:to_i).uniq.sort : base.weekdays,
          lead_minutes: params[:lead_minutes].presence&.to_i || base.lead_minutes,
          notify_bus_change: flag.call(:bus_change, base.bus_change), notify_service_days: flag.call(:service_days, base.service_days),
          notify_late: flag.call(:late, base.late), notify_notices: flag.call(:notices, base.notices) }
      end

      # Every timing the route's screen lists (its directions' runs).
      def timing_ids(trip) = Shuttles.directions(trip).flat_map { |d| trip.runs.select { it.direction == d }.map(&:id) }

      # Pause Alerts: "Alerts Start Again On" a date after today (company time is not needed: the person picks a calendar day).
      def pause(account:, until_date:)
        date = Date.iso8601(until_date.to_s)
        raise ApplicationService::Error, "Pick a date after today" unless date > Date.current

        account.update!(shuttle_alerts_paused_until: date)
        date
      rescue Date::Error
        raise ApplicationService::Error, "Pick a date after today"
      end

      def resume(account:) = account.update!(shuttle_alerts_paused_until: nil)

      # nil once the date has come (Resume is automatic).
      def paused_until(account, today: Date.current) = account.shuttle_alerts_paused_until.presence&.then { it > today ? it : nil }
    end
  end
end
