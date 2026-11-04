# A row of a rule's condition (removed with the team it names).
# == Schema Information
#
# Table name: client_approval_rule_teams
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  client_approval_rule_id :bigint           not null
#  client_team_id          :bigint           not null
#
# Indexes
#
#  index_client_approval_rule_teams_on_client_team_id  (client_team_id)
#  index_client_approval_rule_teams_unique             (client_approval_rule_id,client_team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (client_approval_rule_id => client_approval_rules.id) ON DELETE => cascade
#  fk_rails_...  (client_team_id => client_teams.id) ON DELETE => cascade
#
class ClientApprovalRuleTeam < ApplicationRecord
  self.table_name = "client_approval_rule_teams"

  belongs_to :client_approval_rule
  belongs_to :client_team
end
