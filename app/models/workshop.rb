# == Schema Information
#
# Table name: workshops
# Database name: primary
#
#  id         :bigint           not null, primary key
#  address    :text
#  name       :string           not null
#  phone      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_workshops_on_company_id           (company_id)
#  index_workshops_on_company_id_and_name  (company_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A workshop the company sends its buses to (Workshops window). One used by a visit can't be deleted.
class Workshop < ApplicationRecord
  include TenantScoped
  audited

  has_many :visits, class_name: "MaintenanceVisit", dependent: :restrict_with_error

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }

  # The workshop with this name (any case), or a new one.
  def self.named(name) = where("LOWER(name) = ?", name.to_s.squish.downcase).first || new(name:)
end
