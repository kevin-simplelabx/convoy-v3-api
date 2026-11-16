# Convoy App › Pick a Point › My Points: a place a person saved for their bookings (every booking account of theirs).
# == Schema Information
#
# Table name: app_saved_points
# Database name: primary
#
#  id             :bigint           not null, primary key
#  address        :string
#  lat            :decimal(10, 7)
#  lng            :decimal(10, 7)
#  name           :string           not null
#  note           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#
# Indexes
#
#  index_app_saved_points_on_account_and_name  (app_account_id, lower((name)::text)) UNIQUE
#  index_app_saved_points_on_app_account_id    (app_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#
class AppSavedPoint < ApplicationRecord
  audited associated_with: :app_account

  belongs_to :app_account

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :app_account_id, case_sensitive: false }
  validates :lat, numericality: { in: -90..90 }, allow_nil: true
  validates :lng, numericality: { in: -180..180 }, allow_nil: true
end
