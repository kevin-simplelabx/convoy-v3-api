# A staff shuttle rider as the office sees them: the name the person gave the app, the work email that matched and where the
# invitation stands (invited = not answered yet, accepted, declined = Not Me).
class ClientRiderBlueprint < ApplicationBlueprint
  fields :client_id, :matched_email, :status, :responded_at, :created_at

  field(:name) { |r| r.app_account.display_name || "Convoy App user" }
end
