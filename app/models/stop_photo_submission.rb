# A photo a parent or driver sent for a photo request (from the Convoy App, or recorded by the office: Add Received
# Photos, "photo n of m"): pending, then accepted (it becomes the point's photo, credited to them) or rejected.
# == Schema Information
#
# Table name: stop_photo_submissions
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  annotations           :jsonb
#  batch_index           :integer
#  batch_size            :integer
#  photo                 :string           not null
#  role                  :string           not null
#  source                :string           default("app"), not null
#  status                :string           default("pending"), not null
#  street_view_url       :string
#  submitted_at          :timestamptz      not null
#  submitted_by_name     :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  recorded_by_id        :bigint
#  stop_photo_request_id :bigint           not null
#
# Indexes
#
#  index_stop_photo_submissions_on_recorded_by_id         (recorded_by_id)
#  index_stop_photo_submissions_on_stop_photo_request_id  (stop_photo_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (stop_photo_request_id => stop_photo_requests.id) ON DELETE => cascade
#
class StopPhotoSubmission < ApplicationRecord
  include TenantScoped
  audited associated_with: :stop_photo_request

  mount_uploader :photo, ImageUploader

  SOURCES = %w[app office].freeze

  belongs_to :stop_photo_request, inverse_of: :submissions
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :role, inclusion: { in: %w[parent driver] }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  validates :source, inclusion: { in: SOURCES }
end
