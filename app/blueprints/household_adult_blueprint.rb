# An adult of the Household list. Pass viewer: the signed-in account's member row.
# status: active | invited (waiting for them to accept; "Invited" badge). needs_photo: "Add a photo before they can receive the
# children"; can_add_photo: the add-photo button (anyone in the Family without one).
class HouseholdAdultBlueprint < Blueprinter::Base
  identifier :id
  fields :relationship, :admin, :billing_contact, :status

  field(:name, &:name)
  field(:first_name, &:first_name)
  field(:phone, &:phone_display)
  field(:photo) { |m| m.photo_info }
  field(:you) { |m, o| m.id == o[:viewer].id }
  field(:needs_photo) { |m, o| m.active? && m.id != o[:viewer].id && !m.parent? && m.photo.blank? }
  field(:can_add_photo) { |m| m.active? && m.photo.blank? }
end
