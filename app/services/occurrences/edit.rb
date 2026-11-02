# What a person does to one run from the Scheduler drawer: cancel and restore, raise and clear an issue, change the
# pick-up time for this run only or for every run from this date. Each change is audited with the trip, records the
# field as overridden (Sync keeps it), and checks lock_version (409 when someone else just changed the run).
module Occurrences
  class Edit
    def initialize(occurrence, user, lock_version: nil)
      @occ = occurrence
      @user = user
      @occ.lock_version = lock_version.to_i if lock_version.present?
    end

    # by_client: cancelled at the client's request (Trip History: Cancelled by Client), else by us.
    def cancel!(by_client: false)
      raise ApplicationService::Error, "This run is already cancelled" if @occ.cancelled?

      save!(status: "cancelled", cancelled_at: Time.current, cancelled_by: @user, cancelled_by_client: by_client, overridden_fields: add(:status))
    end

    def restore!
      raise ApplicationService::Error, "This run is not cancelled" unless @occ.cancelled?

      status = @occ.ends_at <= Time.current ? "completed" : "scheduled"
      save!(status:, cancelled_at: nil, cancelled_by: nil, cancelled_by_client: false, overridden_fields: drop(:status))
    end

    # Raise an Issue: only on a run that is done; holds the driver's pay for it until cleared.
    def raise_issue!(reason)
      pay_confirmed!
      raise ApplicationService::Error, "Say what the issue is" if reason.blank?
      raise ApplicationService::Error, "An issue can be raised on a completed run only" unless done?

      save!(issue_reason: reason.squish, issue_raised_at: Time.current, issue_raised_by: @user)
    end

    def clear_issue!
      pay_confirmed!
      save!(issue_reason: nil, issue_raised_at: nil, issue_raised_by: nil)
    end

    # Today Only: this run moves; every stop moves by the same amount.
    def shift_today!(start_time)
      raise ApplicationService::Error, "School route times are set in School Bus" if @occ.school_route_id

      delta = Clock.minutes(start_time) - @occ.start_time
      raise ApplicationService::Error, "Pick a different time" if delta.zero?

      move!(@occ.shift_minutes + delta)
    end

    # Back to Regular Bus: drop the bus set by hand on this run; it takes the bus its plan says again.
    def reset_vehicle!
      raise ApplicationService::Error, "This run is on its regular bus" unless @occ.overridden?(:vehicle_id)
      raise ApplicationService::Error, "This run has started" if @occ.starts_at <= Time.current

      TripOccurrence.transaction do
        save!(overridden_fields: @occ.overridden_fields - %w[vehicle_id operator_cost], source_digest: nil)
        Sync.call(trips: [ @occ.trip_id ].compact, routes: [ @occ.school_route_id ].compact, from: @occ.date, to: @occ.date)
      end
      @occ.reload
    end

    # Back to the planned time.
    def reset_time!
      move!(0)
    end

    # Every Run From This Date: the trip (or this shuttle run) moves from the run's date on.
    def change_from_here!(start_time)
      trip = @occ.trip
      raise ApplicationService::Error, "School route times are set in School Bus" if trip.nil?
      raise ApplicationService::Error, "Only a recurring trip has later runs" unless trip.recurring?

      delta = Clock.minutes(start_time) - @occ.start_time
      raise ApplicationService::Error, "Pick a different time" if delta.zero?

      TripOccurrence.transaction do
        current = trip.time_changes.select { |c| c.effective_from <= @occ.date && (c.trip_run_id.nil? || c.trip_run_id == @occ.trip_run_id) }
                      .max_by { |c| [ c.effective_from, c.trip_run_id ? 1 : 0, c.id ] }&.minutes.to_i
        trip.time_changes.create!(effective_from: @occ.date, minutes: current + delta - @occ.shift_minutes,
                                  trip_run: @occ.trip_run, created_by: @user)
        move!(0) if @occ.shift_minutes.nonzero?
        Sync.call(trips: [ trip ], from: @occ.date)
      end
      @occ.reload
    end

    private

    # A driver's pay for a confirmed month is frozen: its runs' issues can't change until it is reopened.
    def pay_confirmed!
      return unless DriverPayMonth.confirmed_for?(@occ.driver_id, @occ.date)

      raise ApplicationService::Error, "Driver pay for #{@occ.date.strftime('%B %Y')} is confirmed. Reopen it in HR, Earnings first"
    end

    def done? = @occ.completed? || @occ.ended_at.present? || @occ.ends_at <= Time.current

    def move!(shift)
      delta = shift - @occ.shift_minutes
      save!(shift_minutes: shift, start_time: @occ.start_time + delta, end_time: @occ.end_time + delta,
            starts_at: @occ.starts_at + delta.minutes, ends_at: @occ.ends_at + delta.minutes,
            overridden_fields: shift.zero? ? drop(:shift_minutes) : add(:shift_minutes))
    end

    def add(field) = (@occ.overridden_fields | [ field.to_s ])
    def drop(field) = (@occ.overridden_fields - [ field.to_s ])

    def save!(attrs)
      raise ApplicationService::Error, "This run does not run that day (#{@occ.skip_reason})" if @occ.skipped?

      @occ.update!(attrs)
      @occ
    end
  end
end
