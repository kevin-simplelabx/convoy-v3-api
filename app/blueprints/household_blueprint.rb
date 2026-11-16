# The Household screen: family and address, adults, Asked to Join (Admin only), children. Pass viewer: the signed-in
# account's member row (decorated members / dependants are built here). can_delete = Admin, who may try Delete Family.
class HouseholdBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :postal, :block, :street, :floor, :unit, :line2, :address, :billing_same, :billing_address

  field(:you) { |_h, o| { member_id: o[:viewer].id, admin: o[:viewer].admin?, billing_contact: o[:viewer].billing_contact? } }
  field(:can_delete) { |_h, o| o[:viewer].admin? }
  field(:adults) do |h, o|
    adults = h.members.select { it.active? || it.invited? }
    HouseholdAdultBlueprint.render_as_hash(adults.map(&:decorate), viewer: o[:viewer])
  end
  field(:asked_to_join) do |h, o|
    o[:viewer].admin? ? HouseholdRequestBlueprint.render_as_hash(h.members.select(&:requested?)) : []
  end
  field(:children) do |h|
    DependantBlueprint.render_as_hash(h.dependants.map(&:decorate), statuses: ConvoyApp::Households::BusService.statuses(h))
  end
end
