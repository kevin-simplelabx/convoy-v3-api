# The company's Share Form link for hired drivers (External Vehicles). One live link per company; making a new one
# revokes the old (it stops working), answers already sent are kept.
# == Schema Information
#
# Table name: external_vehicle_share_links
# Database name: primary
#
#  id            :bigint           not null, primary key
#  revoked_at    :datetime
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  created_by_id :bigint
#
# Indexes
#
#  index_external_share_links_one_live                  (company_id) UNIQUE WHERE (revoked_at IS NULL)
#  index_external_vehicle_share_links_on_company_id     (company_id)
#  index_external_vehicle_share_links_on_created_by_id  (created_by_id)
#  index_external_vehicle_share_links_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
class ExternalVehicleShareLink < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :created_by, class_name: "User", optional: true
  has_many :submissions, class_name: "ExternalVehicleSubmission", foreign_key: :share_link_id, inverse_of: :share_link,
                         dependent: :restrict_with_error

  has_secure_token :token, length: 24

  scope :live, -> { where(revoked_at: nil) }

  # The live link, made on first use.
  def self.current!(user: nil) = live.first || create!(created_by: user)

  # New link: the old one stops working.
  def self.reset!(user:)
    transaction do
      live.update_all(revoked_at: Time.current)
      create!(created_by: user)
    end
  end

  def live? = revoked_at.nil?
end
