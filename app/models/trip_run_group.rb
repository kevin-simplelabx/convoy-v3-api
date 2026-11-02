# == Schema Information
#
# Table name: trip_run_groups
# Database name: primary
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  trip_id    :bigint           not null
#
# Indexes
#
#  index_trip_run_groups_on_company_id  (company_id)
#  index_trip_run_groups_on_trip_id     (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#
# Runs That Move Together: dragging one run slot of the group moves them all.
class TripRunGroup < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip
  has_many :slots, class_name: "TripRunSlot", dependent: :nullify
end
