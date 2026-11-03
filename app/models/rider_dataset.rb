# A school's rider list uploaded as a file (Rider Data), used from its Effective From date until a later list. Homes are
# placed by OneMap in the background (status locating → ready); riders OneMap does not know have No Location.
# == Schema Information
#
# Table name: rider_datasets
# Database name: primary
#
#  id              :bigint           not null, primary key
#  effective_from  :date             not null
#  file            :string
#  file_name       :string           not null
#  riders_count    :integer          default(0), not null
#  status          :string           default("locating"), not null
#  unlocated_count :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  school_id       :bigint           not null
#  uploaded_by_id  :bigint
#
# Indexes
#
#  index_rider_datasets_on_school_id_and_effective_from  (school_id,effective_from)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (uploaded_by_id => users.id)
#
class RiderDataset < ApplicationRecord
  include TenantScoped
  audited associated_with: :school, except: %w[riders_count unlocated_count status]

  mount_uploader :file, DocumentUploader

  belongs_to :school
  belongs_to :uploaded_by, class_name: "User", optional: true
  has_many :riders, class_name: "SchoolRider", dependent: :delete_all

  enum :status, { locating: "locating", ready: "ready" }, validate: true

  validates :effective_from, :file_name, presence: true

  # The list in use on a date: the latest one effective on or before it.
  def self.in_use_on(date) = where(effective_from: ..date).reorder(effective_from: :desc, id: :desc).first

  # In Use / Scheduled / Replaced against the list in use on a date.
  def state_on(date, in_use)
    return "in_use" if in_use && id == in_use.id

    effective_from > date ? "scheduled" : "replaced"
  end
end
