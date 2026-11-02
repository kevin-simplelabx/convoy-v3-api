# == Schema Information
#
# Table name: attendants
# Database name: primary
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  notes        :text
#  phone        :string
#  photo        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#
# Indexes
#
#  index_attendants_on_company_id    (company_id)
#  index_attendants_on_discarded_at  (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A bus attendant (crew on school routes and School Runs).
class Attendant < ApplicationRecord
  include TenantScoped
  audited
  include Discard::Model

  mount_uploader :photo, ImageUploader

  normalizes :phone, with: ->(v) { v.to_s.gsub(/[^\d+]/, "").presence }

  validates :name, presence: true

  def self.ransackable_attributes(_auth = nil) = %w[name phone]
end
