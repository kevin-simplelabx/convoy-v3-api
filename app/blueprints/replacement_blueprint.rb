class ReplacementBlueprint < ApplicationBlueprint
  fields :kind, :kind_name, :scope, :trip_id, :school_route_id, :run_date, :trip_run_id, :slot_no, :original_vehicle_id, :starts_on, :ends_on,
         :vehicle_id, :driver_id, :operator_driver_id, :driver_name, :driver_phone, :handover_stop, :eta, :pay_split,
         :original_share, :arranged_by, :deduction, :premium, :reason, :created_at, :summary, :pay_text, :status_label
  field(:handover_time) { |r| r.handover_time_hm }
  field(:original_plate) { |r| r.original_vehicle.plate }
  field(:plate) { |r| r.vehicle&.plate }
  field(:new_driver) { |r| r.new_driver_label }
  field(:created_by) { |r| r.created_by&.name }
  field(:notifications) do |r|
    r.notifications.map { |n| { audiences: n.audiences, channels: n.channels, message: n.message, at: n.created_at, by: n.sent_by&.name } }
  end
end
