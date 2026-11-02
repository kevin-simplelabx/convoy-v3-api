class MaintenanceVisitBlueprint < ApplicationBlueprint
  fields :vehicle_id, :driver_id, :date, :workshop_id, :address, :kind, :kind_name, :work_to_do, :status, :tab, :odometer,
         :gst_on, :gst_rate, :subtotal, :gst, :total, :driver_notified_at, :completed_at, :created_at
  field(:start_time) { |v| v.start_time_hm }
  field(:end_time) { |v| v.end_time_hm }
  field(:plate) { |v| v.vehicle.plate }
  field(:driver_name) { |v| v.driver&.name }
  field(:workshop_name) { |v| v.workshop&.name }
  field(:items_count) { |v| v.lines.size }
  field(:has_invoice) { |v| v.invoices.any? }

  view :full do
    field(:last_odometer) { |v| v.last_odometer }
    field(:tyre_positions) { |v| v.vehicle.tyre_positions }
    field(:lines) do |v|
      v.lines.map do |l|
        l.slice(:id, :position, :line_type, :description, :part_number, :brand, :model, :tyre_position, :quantity, :unit_price).merge(amount: l.amount)
      end
    end
    field(:invoices) { |v| v.invoices.map { |i| { id: i.id }.merge(i.decorate.file_info(:file)) } }
    field(:completed_by) { |v| v.completed_by&.name }
  end
end
