# A row of a rule's condition (removed with the site it names).
# == Schema Information
#
# Table name: client_approval_rule_sites
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  client_approval_rule_id :bigint           not null
#  client_site_id          :bigint           not null
#
# Indexes
#
#  index_client_approval_rule_sites_on_client_site_id  (client_site_id)
#  index_client_approval_rule_sites_unique             (client_approval_rule_id,client_site_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (client_approval_rule_id => client_approval_rules.id) ON DELETE => cascade
#  fk_rails_...  (client_site_id => client_sites.id) ON DELETE => cascade
#
class ClientApprovalRuleSite < ApplicationRecord
  self.table_name = "client_approval_rule_sites"

  belongs_to :client_approval_rule
  belongs_to :client_site
end
