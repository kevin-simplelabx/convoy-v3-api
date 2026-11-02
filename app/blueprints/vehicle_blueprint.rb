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

  # The vehicle record dialog. fuel: Fuel & Energy summary (own buses); financials: the Vehicle Financials summary
  # (only for users with the vehfin permission: pass vehfin: true).
  view :record do
    field(:upcoming_drivers) { |v| v.upcoming_drivers }
    field(:fuel) { |_v, options| options[:fuel] }
    field(:financials) do |v, options|
      f = options[:vehfin] && v.own? ? v.object.financial : nil
      next nil unless options[:vehfin] && v.own?
      next { status: "no_details" } unless f

      s = f.schedule
      { status: f.status, funding: f.funding, purchase_price: f.purchase_price, bought_on: f.bought_on, lender: f.lender,
        loan_amount: f.loan_amount, monthly: s.valid? ? s.monthly : nil, owed: s.valid? ? s.owed : nil, ends_on: s.rows.last&.due_on }
    end
  end
end
