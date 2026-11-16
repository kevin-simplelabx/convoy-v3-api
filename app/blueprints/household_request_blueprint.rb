# One person under Asked to Join (opened the Quick Invite link): the Admin sets the relationship and approves or declines.
class HouseholdRequestBlueprint < Blueprinter::Base
  identifier :id
  field(:name, &:name)
  field(:first_name, &:first_name)
  field(:phone, &:phone_display)
  field(:requested_at) { |m| m.created_at }
end
