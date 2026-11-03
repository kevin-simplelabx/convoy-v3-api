# The signed-in person in the Convoy Driver app: short in the session, the full portable profile in view :profile
# (Account › Personal Details, Complete My Profile, Driving Credentials). Render a decorated account.
class DriverAccountBlueprint < Blueprinter::Base
  identifier :id
  fields :phone, :phone_display, :name, :email

  field(:password_set) { |a| a.password_set? }
  field(:photo) { |a| a.photo_info }

  view :profile do
    fields :date_of_birth, :nationality, :residential_status, :id_label, :address, :postal_code, :full_address
    field(:id_number) { |a| a.id_number_masked }
    field(:phone_verified) { |a| a.phone_verified_at.present? }
    field(:singpass) { |a| { verified: a.singpass_verified?, verified_at: a.singpass_verified_at, fields: a.locked_fields } }
    field(:completeness) { |a| a.completeness }
    field(:licences) { |a| DriverLicenceBlueprint.render_as_hash(a.licences.map(&:decorate)) }
  end
end
