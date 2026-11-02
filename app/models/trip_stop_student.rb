# == Schema Information
#
# Table name: trip_stop_students
# Database name: primary
#
#  id           :bigint           not null, primary key
#  class_name   :string
#  key          :uuid             not null
#  name         :string           not null
#  note         :text
#  parent_name  :string
#  phone        :string
#  phone2       :string
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#  trip_stop_id :bigint           not null
#
# Indexes
#
#  index_trip_stop_students_on_company_id    (company_id)
#  index_trip_stop_students_on_key           (key)
#  index_trip_stop_students_on_trip_stop_id  (trip_stop_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_stop_id => trip_stops.id)
#
# A student picked up or dropped off at a School Run stop. key stays the same when a new route list is imported.
class TripStopStudent < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip_stop

  belongs_to :trip_stop, inverse_of: :students

  normalizes :phone, :phone2, with: ->(v) { v.to_s.gsub(/[^\d+]/, "").presence }

  validates :name, presence: true
end
