# A route plan: the list row (state, bus mix, riders, unassigned, Out of Date) and (view :detail) its summary, parameters,
# unassigned riders with reasons, routes with stops and riders, and comments.
class SchoolPlanBlueprint < ApplicationBlueprint
  fields :name, :session, :source, :priority, :effective_from, :effective_to, :created_at, :adopted_at
  field(:state) { |p| p.state }
  field(:created_by) { |p| p.created_by&.name }
  field(:routes_count) { |p| p.routes.size }
  field(:riders) { |p| p.routes.sum(&:riders_count) }
  field(:bus_mix) { |p| p.routes.group_by(&:bus_type).transform_values(&:size) }
  field(:unassigned_count) { |p| Array(p.unassigned).sum { it["n"] || Array(it["riders"]).size } }
  field(:comments_count) { |p| p.comments.size }
  # Out of Date: its riders or the school's stops changed after it was made.
  field(:out_of_date) { |p| p.stale || (p.school.stops_changed_at.present? && p.school.stops_changed_at > p.created_at) }

  view :detail do
    fields :summary, :params, :unassigned
    field(:routing_run) do |p|
      r = p.routing_run
      r && { id: r.id, no_stop: Routing.rider_list(p.school, r.no_stop_rids), conflicts: Routing.rider_list(p.school, r.conflict_rids), ms: r.ms }
    end
    field(:routes) { |p| SchoolRouteBlueprint.render_as_hash(p.routes) }
    field(:comments) { |p| p.comments.map { { id: it.id, body: it.body, by: it.user&.name, at: it.created_at } } }
  end
end
