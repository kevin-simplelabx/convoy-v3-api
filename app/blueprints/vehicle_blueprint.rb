class VehicleBlueprint < ApplicationBlueprint
  fields :plate, :seats, :make, :year_made, :tags, :notes, :ownership, :size, :size_name,
         :default_picture, :driver_name, :driver_phone, :chassis_number, :engine_number, :registered_on,
         :coe_expires_on, :road_tax_expires_on, :source
  # The record's own model (Draper's `model` is the wrapped record, so it is read from the object).
  field(:model) { |v| v.object.model }
  field(:vip) { |v| v.vip? }
  field(:photo) { |v| v.photo_info }
  field(:driver) { |v| v.driver_today }
  field(:plate_conflict) { |v| v.plate_conflict? }
  field(:insurance) { |v| v.insurance_summary }
  association :operator, blueprint: OperatorBlueprint, view: :default
  association :vehicle_team, blueprint: VehicleTeamBlueprint

  # The vehicle record dialog. fuel: Fuel & Energy summary (own buses); financials stay null until the Finance menu
  # builds Vehicle Financials.
  view :record do
    field(:upcoming_drivers) { |v| v.upcoming_drivers }
    field(:fuel) { |_v, options| options[:fuel] }
    field(:financials) { nil }
  end
end
