class VehicleBlueprint < Blueprinter::Base
  identifier :id do |v| v.id.to_s end

  field(:plate)       { |v| v.plate.to_s }
  field(:vehicleType) { |v| v.vehicle_type.to_s }
  field(:seats)       { |v| v.seats }
  field(:driverName)  { |v| v.driver_name.to_s }
  field(:driverContact) { |v| v.driver_contact.to_s }
  field(:driverPhoto) { |v| v.driver_photo.to_s }
  field(:operatorId)  { |v| v.operator_id.to_s }
  field(:operatorName) { |v| v.operator_name.to_s }
  field(:operatorContact) { |v| v.operator_contact.to_s }
  field(:operatorPhone)   { |v| v.operator_phone.to_s }
  field(:tags)  { |v| v.tags.is_a?(Array) ? v.tags : [] }
  field(:photo) { |v| v.photo.to_s }
  field(:notes) { |v| v.notes.to_s }
  field(:sample) { |v| !!v.sample }
  field(:coeExp) { |v| v.respond_to?(:coe_exp) ? v.coe_exp.to_s : '' }
  field(:taxExp) { |v| v.respond_to?(:tax_exp) ? v.tax_exp.to_s : '' }
  field(:insTo)  { |v| v.respond_to?(:ins_to) ? v.ins_to.to_s : '' }
end
