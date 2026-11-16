# Convoy App › Shuttles › View Schedule: a month (this month up to today + 92 days; each day no service / changed times / has
# changes) and the timetable of the picked day: a row per timing with its time at every stop (a run that skips a stop has nil).
#   Schedule.call(account:, employer:, trip_id:, month: nil, date: nil, direction: nil, now: Time.current)
module ConvoyApp
  module Shuttles
    class Schedule < ApplicationService
      def initialize(account:, employer:, trip_id:, month: nil, date: nil, direction: nil, now: Time.current)
        @account = account
        @employer = employer
        @trip_id = trip_id
        @month = month
        @date = date
        @direction = direction
        @now = now
      end

      def call
        Shuttles.within(@employer) do
          today = Time.zone.today
          trip = Shuttles.trip!(@employer, @trip_id, today)
          dirs = Shuttles.directions(trip)
          raise ActiveRecord::RecordNotFound if dirs.empty?

          direction = @direction.presence ? @direction.to_i : dirs.first
          raise ApplicationService::Error, "This route has no #{DIRECTIONS[direction].to_s.downcase} direction" unless dirs.include?(direction)

          last = today + SCHEDULE_DAYS
          first_of = today.beginning_of_month
          date = @date.present? ? parse(@date) : today
          raise ApplicationService::Error, "Pick a day from today to #{last}" unless date.between?(today, last)

          month = @month.present? ? parse("#{@month}-01").beginning_of_month : date.beginning_of_month
          raise ApplicationService::Error, "Pick a month from #{first_of.strftime('%Y-%m')} to #{last.strftime('%Y-%m')}" unless month.between?(first_of, last.beginning_of_month)

          days = Days.new(trip, month, [ month.end_of_month, today ].max)
          usual = UsualOf.for(@account, @employer.client)
          {
            employer: @employer.json, route: RoutePage.route_json(trip, pinned: ShuttlePin.exists?(app_account_id: @account.id, trip_id: trip.id), usual:),
            direction:, direction_name: DIRECTIONS.fetch(direction), month: month.strftime("%Y-%m"), first_month: first_of.strftime("%Y-%m"), last_month: last.strftime("%Y-%m"),
            today:, date:, days: month_days(days, month, today, last), timetable: timetable(trip, days, date, direction, usual)
          }
        end
      end

      private

      def parse(text)
        Date.iso8601(text.to_s)
      rescue Date::Error
        raise ApplicationService::Error, "That is not a date"
      end

      def month_days(days, month, today, last)
        (month..month.end_of_month).map do |d|
          day = days.day(d)
          { date: d, weekday: d.wday, state: day.state, reason: day.reason, changes: day.changes, past: d < today, beyond: d > last,
            shifts: day.shifts.map { { direction: it[:direction], minutes: it[:minutes] } } }
        end
      end

      def timetable(trip, days, date, direction, usual)
        day = days.day(date)
        stops = trip.stops_in(direction)
        header = stops.map { { stop_id: it.id, name: it.name_in(direction) } }
        return { day: { state: day.state, reason: day.reason }, stops: header, timings: [] } if day.state == "no_service"

        timings = Timings.new(trip, date, days:, now: @now).list(direction).map do |t|
          lead = t.occurrences.find { !it.cancelled? } || t.occurrences.first
          { run_id: t.run.id, time: lead.start_time_hm, state: t.state, usual: usual.run?(t.run), change: t.change,
            times: Occurrences::Stops.planned(lead).map { it[:planned_time] } }
        end
        { day: { state: day.state, reason: day.reason }, stops: header, timings: }
      end
    end
  end
end
