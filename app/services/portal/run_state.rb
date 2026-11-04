# Where a run is for the Client Portal (logic/app-feed.js liveState): scheduled, on_the_way, started, ended. With the
# Driver app: On the Way once the driver starts, Started once they leave the first stop, Ended when they end it. Without
# it: On the Way from 30 minutes before the start, Started at the start, Ended at the planned end. Cancelled = ended.
module Portal
  module RunState
    LABELS = { "scheduled" => "Scheduled", "on_the_way" => "On the way", "started" => "Started", "ended" => "Ended" }.freeze

    def self.call(occ, now = Time.current)
      return "ended" if occ.ended_at || occ.completed? || occ.cancelled?
      return occ.stop_events.any?(&:departed_at) ? "started" : "on_the_way" if occ.started_at
      return "ended" if now >= occ.ends_at
      return "started" if now >= occ.starts_at
      return "on_the_way" if now >= occ.starts_at - 30.minutes

      "scheduled"
    end

    def self.on_road?(state) = %w[on_the_way started].include?(state)
  end
end
