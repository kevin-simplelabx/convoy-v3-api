# A request for photos of a PUDO point through the Convoy App: from the parents of riders at the stop, the driver, both,
# or one parent (school_rider); up to max_submissions photos; auto = opened by the company's automatic requests.
# == Schema Information
#
# Table name: stop_photo_requests
# Database name: primary
#
#  id              :bigint           not null, primary key
#  audience        :string           default("parents"), not null
#  auto            :boolean          default(FALSE), not null
#  max_submissions :integer          default(6), not null
#  status          :string           default("open"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  school_rider_id :bigint
#  stop_point_id   :bigint           not null
#
# Indexes
#
#  index_stop_photo_requests_on_stop_point_id_and_status  (stop_point_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_rider_id => school_riders.id) ON DELETE => nullify
#  fk_rails_...  (stop_point_id => stop_points.id) ON DELETE => cascade
#
class StopPhotoRequest < ApplicationRecord
  include TenantScoped
  audited

  AUDIENCES = %w[parents driver both parent].freeze

  belongs_to :stop_point
  belongs_to :school_rider, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :submissions, -> { order(:submitted_at) }, class_name: "StopPhotoSubmission", dependent: :destroy, inverse_of: :stop_photo_request

  validates :audience, inclusion: { in: AUDIENCES }
  validates :status, inclusion: { in: %w[open closed] }
  validates :max_submissions, numericality: { only_integer: true, in: 1..12 }

  scope :open, -> { where(status: "open") }

  def live_count = submissions.to_a.count { it.status != "rejected" }
end
