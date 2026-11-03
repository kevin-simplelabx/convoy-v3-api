# Bus Sessions › Save & Lock (needs the year's calendar locked): every session with its days (operating days only),
# times and day variants. To school: arrival window. To home / CCA: dismissal, departure and arrival window.
module BusSessions
  class Save < ApplicationService
    TIMES = %i[arrive_from arrive_to dismissal depart].freeze

    def initialize(year, sessions, user:)
      @year = year
      @sessions = Array(sessions)
      @user = user
    end

    def call
      school = @year.school
      raise Error, "Save and lock the Terms & Semesters first" unless SchoolSetup.locked?(school:, year: @year, section: :calendar)

      SchoolSetup.ensure_unlocked!(school:, year: @year, section: :sessions)
      raise Error, "Add at least one session" if @sessions.empty?

      BusSession.transaction do
        @year.bus_sessions.destroy_all
        @sessions.each.with_index(1) { |s, i| create(s, i) }
        names = @year.bus_sessions.reload.map { it.name.downcase }
        raise Error, "Session names must be different" if names.uniq.size != names.size

        SchoolSetup.lock!(school:, year: @year, section: :sessions, user: @user)
      end
    end

    private

    def create(s, i)
      label = s[:name].presence || "Session #{i}"
      days = days(s[:days], label)
      session = @year.bus_sessions.create!(s.slice(:name, :direction, :service, :max_journey_minutes, :notes, *TIMES)
                                            .merge(position: i, cca: s[:cca] || false, days:))
      check_times!(session, label)
      taken = []
      Array(s[:variants]).each.with_index(1) do |v, k|
        vdays = days(v[:days], "#{label} Different Timing #{k}")
        raise Error, "#{label} Different Timing #{k}: pick days the session runs" unless (vdays - days).empty?
        raise Error, "#{label} Different Timing #{k}: a day is in two timings" if taken.intersect?(vdays)

        taken.concat(vdays)
        variant = session.variants.create!(v.slice(*TIMES).merge(position: k, days: vdays))
        check_times!(variant, "#{label} Different Timing #{k}", home: session.to_home?)
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Error, "#{label}: #{e.record.errors.full_messages.to_sentence}"
    end

    def days(list, label)
      days = Array(list).map(&:to_i).uniq.sort
      raise Error, "#{label}: pick at least one day" if days.empty?
      raise Error, "#{label}: pick operating days only" unless (days - @year.operating_days).empty?

      days
    end

    def check_times!(row, label, home: row.respond_to?(:to_home?) && row.to_home?)
      raise Error, "#{label}: set the arrival window" unless row.arrive_from && row.arrive_to
      raise Error, "#{label}: the arrival window must end after it starts" unless row.arrive_to > row.arrive_from
      return unless home

      raise Error, "#{label}: set the dismissal and departure times" unless row.dismissal && row.depart
      raise Error, "#{label}: departure must be at or after dismissal" if row.depart < row.dismissal
      raise Error, "#{label}: arrival home cannot start before departure" if row.arrive_from < row.depart
    end
  end
end
