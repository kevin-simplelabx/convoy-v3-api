class FuelEntryBlueprint < ApplicationBlueprint
  fields :vehicle_id, :date, :kind, :kind_name, :unit, :quantity, :cost, :unit_price, :odometer, :full, :fuel_company_id,
         :station, :note, :km_since, :efficiency, :odometer_back, :driver_id, :document_read_id, :created_at
  field(:time) { |e| e.time_hm }
  field(:plate) { |e| e.vehicle.plate }
  field(:fuel_company_name) { |e| e.fuel_company&.name }
  field(:driver_name) { |e| e.driver&.name }
  field(:created_by) { |e| e.created_by&.name }
  field(:receipt) { |e| e.receipt_info }
end
