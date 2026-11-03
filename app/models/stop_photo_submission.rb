# A photo a parent or driver sent for a photo request (from the Convoy App; seeded until it exists): pending, then
# accepted (it becomes the point's photo, credited to them) or rejected.
# == Schema Information
#
# Table name: stop_photo_submissions
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  annotations           :jsonb
#  photo                 :string           not null
#  role                  :string           not null
#  status                :string           default("pending"), not null
#  street_view_url       :string
#  submitted_at          :timestamptz      not null
#  submitted_by_name     :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  stop_photo_request_id :bigint           not null
#
# Indexes
#
#  index_stop_photo_submissions_on_stop_photo_request_id  (stop_photo_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (stop_photo_request_id => stop_photo_requests.id) ON DELETE => cascade
#
class StopPhotoSubmission < ApplicationRecord
  include TenantScoped
  audited associated_with: :stop_photo_request

  mount_uploader :photo, ImageUploader

  belongs_to :stop_photo_request, inverse_of: :submissions

  validates :role, inclusion: { in: %w[parent driver] }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
end
