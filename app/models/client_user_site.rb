# A site a client user with a site role acts for.
# == Schema Information
#
# Table name: client_user_sites
# Database name: primary
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  client_site_id :bigint           not null
#  client_user_id :bigint           not null
#
# Indexes
#
#  index_client_user_sites_on_client_site_id                     (client_site_id)
#  index_client_user_sites_on_client_user_id_and_client_site_id  (client_user_id,client_site_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (client_site_id => client_sites.id)
#  fk_rails_...  (client_user_id => client_users.id)
#
class ClientUserSite < ApplicationRecord
  audited associated_with: :client_user

  belongs_to :client_user
  belongs_to :client_site

  validates :client_site_id, uniqueness: { scope: :client_user_id }
end
