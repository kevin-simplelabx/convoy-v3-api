# A row of a rule's condition (removed with the user it names).
# == Schema Information
#
# Table name: client_approval_rule_bookers
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  client_approval_rule_id :bigint           not null
#  client_user_id          :bigint           not null
#
# Indexes
#
#  index_client_approval_rule_bookers_on_client_user_id  (client_user_id)
#  index_client_approval_rule_bookers_unique             (client_approval_rule_id,client_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (client_approval_rule_id => client_approval_rules.id) ON DELETE => cascade
#  fk_rails_...  (client_user_id => client_users.id) ON DELETE => cascade
#
class ClientApprovalRuleBooker < ApplicationRecord
  self.table_name = "client_approval_rule_bookers"

  belongs_to :client_approval_rule
  belongs_to :client_user
end
