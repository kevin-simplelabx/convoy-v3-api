class NoticeBlueprint < ApplicationBlueprint
  fields :audience, :trip_id, :all_runs, :to_riders, :to_parents, :banner, :push, :sms, :starts_at, :ends_at,
         :notice_template_id, :message, :ended_at, :created_at
  field(:state) { |n| n.state }
  field(:trip_title) { |n| n.trip&.title }
  field(:school_id) { |n| n.school_id }
  field(:route_ids) { |n| n.for_school? ? (n.all_runs? ? [ "all" ] : n.route_targets.map(&:school_route_id)) : nil }
  field(:run_keys) { |n| n.all_runs? ? [ "all" ] : n.runs.map { |r| r.trip_run.key } }
  field(:client_name) { |n| n.trip&.client&.name }
  field(:service_for) { |n| n.trip&.service_for }
  field(:school_name) { |n| n.school&.name }
  # Timings picked, for the audience line ("MBC | MBC Campus Shuttle | 07:30, 08:00"); empty for all.
  field(:run_times) { |n| n.all_runs? ? [] : n.runs.map { |r| r.trip_run.start_time_hm } }
  field(:created_by) { |n| n.created_by&.name }
  field(:ended_by) { |n| n.ended_by&.name }
  field(:sent) { |n| n.deliveries.map { |d| { channel: d.channel, recipients: d.recipients, at: d.created_at } } }
end
