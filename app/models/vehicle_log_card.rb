# == Schema Information
#
# Table name: vehicle_log_cards
# Database name: primary
#
#  id             :bigint           not null, primary key
#  current        :boolean          default(TRUE), not null
#  file           :string           not null
#  plate_conflict :boolean          default(FALSE), not null
#  plate_on_card  :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  uploaded_by_id :bigint
#  vehicle_id     :bigint           not null
#
# Indexes
#
#  index_vehicle_log_cards_on_company_id      (company_id)
#  index_vehicle_log_cards_on_uploaded_by_id  (uploaded_by_id)
#  index_vehicle_log_cards_on_vehicle_id      (vehicle_id)
#  index_vehicle_log_cards_one_current        (vehicle_id) UNIQUE WHERE current
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (uploaded_by_id => users.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# A log card file of a vehicle. The newest is current; earlier ones are Past Log Cards.
class VehicleLogCard < ApplicationRecord
  include TenantScoped
  audited

  mount_uploader :file, DocumentUploader

  belongs_to :vehicle
  belongs_to :uploaded_by, class_name: "User", optional: true

  validates :file, presence: true

  scope :current, -> { where(current: true) }
  scope :past, -> { where(current: false).order(created_at: :desc) }
end
