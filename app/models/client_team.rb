# A team of a client's portal users (Client Portal › Settings › Users › Teams). Its manager gets the Their Manager
# approval step for everyone in the team who has no manager of their own.
# == Schema Information
#
# Table name: client_teams
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  client_id  :bigint           not null
#  company_id :bigint           not null
#  manager_id :bigint
#
# Indexes
#
#  index_client_teams_on_client_and_name  (client_id, lower((name)::text)) UNIQUE
#  index_client_teams_on_manager_id       (manager_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (manager_id => client_users.id) ON DELETE => nullify
#
class ClientTeam < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client
  belongs_to :manager, class_name: "ClientUser", optional: true
  has_many :users, class_name: "ClientUser", inverse_of: :team, dependent: nil # the foreign key nullifies

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: { message: "is needed" }
  validates :name, uniqueness: { scope: :client_id, case_sensitive: false, message: "%{value} is already a team" }
  validate :manager_of_client, if: -> { manager && will_save_change_to_manager_id? }

  private

  def manager_of_client
    errors.add(:manager, "is not a user of this client") if manager.client_id != client_id || manager.discarded?
  end
end
