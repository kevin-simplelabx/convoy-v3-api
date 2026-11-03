# One run on the Scheduler.
class TripOccurrenceBlueprint < ApplicationBlueprint
  fields :key, :date, :trip_id, :trip_run_id, :run_key, :slot_no, :part, :trip_label, :kind, :title, :route_text, :client_id,
         :pax, :status, :vehicle_id, :original_vehicle_id, :operator_id, :price, :trip_value, :operator_cost, :shift_minutes,
         :issue_reason, :issue_raised_at, :cancelled_at, :ended_at, :starts_at, :ends_at, :ends_next_day, :overridden_fields, :lock_version,
         :replacement_id, :trip_assignment_id
  field(:start_time) { |o| o.start_time_hm }
  field(:end_time) { |o| o.end_time_hm }
  field(:grid_status) { |o| o.grid_status }
  field(:driver) { |o| o.driver_info }
  field(:plate) { |o| o.vehicle&.plate }
  # The bus a replacement moved this run from: the grid draws a ghost on it.
  field(:original_plate) { |o| o.original_vehicle&.plate }
  field(:recurring) { |o| o.recurring }
  field(:color) { |o| o.color }
  field(:school_route_id) { |o| o.school_route_id }
  # Two-way trips: the other trip of the pair (purple link line from the outbound run to its return).
  field(:pair_trip_id) { |o| o.trip&.pair_id }
  field(:is_return) { |o| o.trip&.is_return || false }
  field(:school_name) { |o| o.school&.short }
  field(:group_key) do |o|
    gid = o.trip_run&.slots&.find { |s| s.slot_no == o.slot_no }&.trip_run_group_id
    gid && "g#{gid}"
  end

  # A row of the Trips page.
  view :list do
    field(:status_group) { |o| o.status_group }
    field(:client_name) { |o| o.client&.name }
    field(:customer) { |o| o.customer }
    field(:vehicle_seats) { |o| o.vehicle&.seats }
    field(:required_vehicle_type) { |o| o.required_vehicle_type }
    field(:operator) { |o| o.operator && { id: o.operator.id, name: o.operator.name, kind: o.operator.kind } }
  end

  view :drawer do
    field(:replacement) { |o| o.replacement && ReplacementBlueprint.render_as_hash(o.replacement.decorate) }
    # The banner notice active on this run now (shown at the top of the drawer).
    field(:notice) do |o|
      n = if o.school_route_id
            Notice.active_at(Time.current).for_school.where(school_id: o.school&.id, banner: true).includes(:route_targets)
                  .order(:starts_at).find { |x| x.covers_route?(o.school_route_id) }
      else
            Notice.active_at(Time.current).where(trip_id: o.trip_id, banner: true).includes(runs: :trip_run).order(:starts_at).find { |x| x.covers_run?(o.trip_run_id) }
      end
      n && { id: n.id, message: n.message, ends_at: n.ends_at }
    end
    field(:trip) { |o| o.trip && TripBlueprint.render_as_hash(o.trip.decorate, view: :full) }
    field(:route) { |o| o.route_detail }
    field(:cancelled_by) { |o| o.cancelled_by&.name }
    field(:issue_raised_by) { |o| o.issue_raised_by&.name }
    # Force End Trip: who ended it (null when the driver ended it in the app).
    field(:ended_by) { |o| o.ended_by&.name }
    # Shuttle runs: how often this run was on another bus lately (suggest a regular bus or No Fixed Bus).
    field(:bus_pattern) { |o| Occurrences::BusPattern.call(o) }
    field(:changes) do |o|
      o.audits.includes(:user).order(:created_at).map { |a| { at: a.created_at, by: a.user&.name, action: a.action, changes: a.audited_changes } }
    end
  end
end
