# == Schema Information
#
# Table name: trip_stop_photos
# Database name: primary
#
#  id           :bigint           not null, primary key
#  photo        :string           not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#  trip_stop_id :bigint           not null
#
# Indexes
#
#  index_trip_stop_photos_on_company_id    (company_id)
#  index_trip_stop_photos_on_trip_stop_id  (trip_stop_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_stop_id => trip_stops.id)
#
class TripStopPhoto < ApplicationRecord
  include TenantScoped
  audited associated_with: :stop

  mount_uploader :photo, ImageUploader

  belongs_to :stop, class_name: "TripStop", foreign_key: :trip_stop_id, inverse_of: :photos

  validates :photo, presence: true
end
