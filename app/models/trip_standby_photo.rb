# == Schema Information
#
# Table name: trip_standby_photos
# Database name: primary
#
#  id              :bigint           not null, primary key
#  photo           :string           not null
#  position        :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  trip_standby_id :bigint           not null
#
# Indexes
#
#  index_trip_standby_photos_on_company_id       (company_id)
#  index_trip_standby_photos_on_trip_standby_id  (trip_standby_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_standby_id => trip_standbys.id)
#
class TripStandbyPhoto < ApplicationRecord
  include TenantScoped
  audited associated_with: :standby

  mount_uploader :photo, ImageUploader

  belongs_to :standby, class_name: "TripStandby", foreign_key: :trip_standby_id, inverse_of: :photos

  validates :photo, presence: true
end
