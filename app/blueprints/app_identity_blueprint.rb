# A row of Mobile and Emails: the value, personal or work, when verified, the work email's next check (state ok / due_soon
# / paused = its links are paused) and what it is used for. Pass uses: [labels].
class AppIdentityBlueprint < Blueprinter::Base
  identifier :id
  fields :kind, :tag, :value, :display, :domain, :verified_at, :reverify_due_on, :reverify_state

  field(:uses) { |_i, options| options[:uses] || [] }
end
