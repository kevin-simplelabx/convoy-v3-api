# Trips: the default view is a list row; :full is everything the trip form and drawer need.
class TripBlueprint < ApplicationBlueprint
  fields :kind, :kind_name, :title, :label, :trip_no, :trip_id, :starts_on, :ends_on, :end_mode, :days, :repeat_text,
         :vehicles_count, :pax, :price, :client_id, :route_text, :is_return, :pair_id, :lock_version
  field(:start_time) { |t| t.start_time_hm }
  field(:end_time) { |t| t.end_time_hm }
  field(:ends_next_day) { |t| t.ends_next_day }
  field(:client_name) { |t| t.client.name }

  view :full do
    fields :client_site_id, :calendar_id, :hours, :occurrence_count, :skip_public_holidays, :trip_no_from, :trip_no_count,
           :luggage_on, :luggage_cabin, :luggage_medium, :luggage_large, :luggage_extra_large, :luggage_oversized,
           :requestor_name, :requestor_email, :requestor_phone, :guest_is_requestor, :guest_name, :guest_phone, :notes,
           :business_unit, :project, :booking_ref, :airport_direction, :flight_number, :terminal, :wait_minutes,
           :meet_and_greet, :signboard_name, :meet_and_greet_fee, :price_per, :price_set, :price_basis, :hourly_rate,
           :trip_value, :trip_value_mode, :trip_value_rounding, :operator_cost, :operator_cancel_rule, :subcontracted,
           :client_end_customer_id, :service_for, :contractor_contact_name, :contractor_contact_phone,
           :require_contractor_app, :return_billing, :vehicles_required_text, :created_at, :updated_at,
           :shuttle_return, :shuttle_separate_return, :price_by, :trip_value_per, :trip_value_return, :route_tags, :color,
           :approved_riders_only, :seat_reservation, :head_count, :no_fixed_bus, :operator_cancel_rule, :session,
           :paid_months_mode, :unpaid_months, :unpaid_month_share, :charge_no_school_days, :school_time_estimated,
           :route_list_name, :route_list_imported_at, :students_purged_at
    field(:flight_time) { |t| Clock.hm(t.flight_time) }
    association :stops, blueprint: TripStopBlueprint
    field(:route_vias) { |t| t.route_vias.map { |v| v.slice(:id, :direction, :from_position, :position, :lat, :lng) } }
    field(:vehicle_requirements) do |t|
      t.vehicle_requirements.map { |r| { id: r.id, vehicle_type_id: r.vehicle_type_id, count: r.count, label: r.label } }
    end
    field(:vehicle_slots) do |t|
      t.vehicle_slots.map { |s| { id: s.id, slot_no: s.slot_no, vehicle_id: s.vehicle_id, plate: s.vehicle&.plate, price: s.price } }
    end
    association :standby, blueprint: TripStandbyBlueprint
    association :runs, blueprint: TripRunBlueprint
    field(:price_table) { |t| t.price_cells.map { |c| { row: c.row_key, col: c.col_key, amount: c.amount } } }
    # Client sites the shuttle serves (two or more = Cross-site Route).
    field(:client_site_ids) { |t| t.stops.filter_map(&:client_site_id).uniq }
    field(:attachments) do |t|
      t.attachments.map { |a| { id: a.id, created_at: a.created_at }.merge(a.decorate.file_info(:file)) }
    end
    field(:pair) { |t| t.pair && { id: t.pair.id, trip_id: t.pair.trip_id_on(t.pair.starts_on), start_time: t.pair.start_time_hm, is_return: t.pair.is_return } }
  end
end
