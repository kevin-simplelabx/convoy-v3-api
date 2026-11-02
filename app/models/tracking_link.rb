# == Schema Information
#
# Table name: tracking_links
# Database name: primary
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime         not null
#  run_date      :date             not null
#  slot_no       :integer          default(1), not null
#  snapshot      :jsonb            not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  created_by_id :bigint
#  trip_id       :bigint           not null
#  trip_run_id   :bigint
#
# Indexes
#
#  index_tracking_links_on_company_id     (company_id)
#  index_tracking_links_on_created_by_id  (created_by_id)
#  index_tracking_links_on_token          (token) UNIQUE
#  index_tracking_links_on_trip_id        (trip_id)
#  index_tracking_links_on_trip_run_id    (trip_run_id)
#  index_tracking_links_one_per_run       (trip_id,run_date,trip_run_id,slot_no) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#
# Share Tracking Link: a public page for one run, from a snapshot taken when shared. Closes 24 hours after the run ends.
class TrackingLink < ApplicationRecord
  include TenantScoped

  OPEN_AFTER_END = 24.hours

  belongs_to :trip
  belongs_to :trip_run, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_secure_token :token, length: 24

  scope :open_at, ->(t) { where("expires_at > ?", t) }

  def open?(now = Time.current) = expires_at > now
end
