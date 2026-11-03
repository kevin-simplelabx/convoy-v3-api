# Acknowledge (row or banner): someone on duty is on it. Stops the alarm and escalation of every open alert of the run;
# the trip stays flagged until the problem clears.
module OpsControl
  class Acknowledge < ApplicationService
    def initialize(occurrence, user, now: Time.current)
      @occ = occurrence
      @user = user
      @now = now
    end

    def call
      count = @occ.ops_alerts.open.unacknowledged.update_all(acknowledged_at: @now, acknowledged_by_id: @user.id, updated_at: @now)
      raise Error, "Nothing to acknowledge on this trip" if count.zero?

      { acknowledged: count, at: @now, by: @user.name }
    end
  end
end
