# Fields shared by own drivers and operator drivers (Drivers and Operator Drivers pages).
class InvitedDriverBlueprint < ApplicationBlueprint
  fields :name, :phone, :phone_display, :status, :invited_at, :responded_at, :status_on
  field(:photo) { |d| d.photo_info }
  field(:display) { |d| d.display_info }
  field(:kyc_shared) { |d| d.kyc_profile.present? }
  field(:last_vehicle) { |d| d.last_vehicle && { id: d.last_vehicle.id, plate: d.last_vehicle.plate } }
end
