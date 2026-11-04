# The signed-in person in the Convoy App (session, Account header, Create Your Account). Render a decorated account.
class AppAccountBlueprint < Blueprinter::Base
  identifier :id
  fields :first_name, :last_name, :name_order, :display_name, :delete_requested_at

  field(:profile_complete) { |a| a.profile_complete? }
  field(:photo) { |a| a.photo_info }
  field(:notifications) { |a| { push: a.notify_push, sms: a.notify_sms, email: a.notify_email } }
  field(:identities) { |a| a.identities.map { { id: it.id, kind: it.kind, tag: it.tag, value: it.value, display: it.display } } }
end
