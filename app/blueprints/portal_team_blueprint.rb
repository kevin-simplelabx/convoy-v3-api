# A team in Client Portal › Settings › Users: its manager and how many people are in it.
class PortalTeamBlueprint < Blueprinter::Base
  identifier :id
  field :name
  field(:manager) { |t| t.manager && { id: t.manager.id, name: t.manager.name } }
  field(:people) { |t| t.users.count(&:kept?) }
end
