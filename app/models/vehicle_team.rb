# == Schema Information
#
# Table name: vehicle_teams
# Database name: primary
#
#  id         :bigint           not null, primary key
#  color      :string           default("#0B6E6E"), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_vehicle_teams_on_company_id           (company_id)
#  index_vehicle_teams_on_company_id_and_name  (company_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A group of vehicles (East, North, Coaches) with a colour, for filters and grouping.
class VehicleTeam < ApplicationRecord
  include TenantScoped
  audited

  has_many :vehicles, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :color, format: { with: /\A#\h{6}\z/ }
end
