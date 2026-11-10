# A drawn outline of a fare zone or a location surcharge (Bus Fares): a ring of [lat, lng] corners; `exclude` cuts it
# out of the outlines it sits in (a home counts when inside an outline and in no cut-out).
# == Schema Information
#
# Table name: fare_areas
# Database name: primary
#
#  id                :bigint           not null, primary key
#  exclude           :boolean          default(FALSE), not null
#  position          :integer          not null
#  ring              :float            not null, is an Array
#  fare_surcharge_id :bigint
#  fare_tier_id      :bigint
#
# Indexes
#
#  index_fare_areas_on_fare_surcharge_id  (fare_surcharge_id)
#  index_fare_areas_on_fare_tier_id       (fare_tier_id)
#
# Foreign Keys
#
#  fk_rails_...  (fare_surcharge_id => fare_surcharges.id) ON DELETE => cascade
#  fk_rails_...  (fare_tier_id => fare_tiers.id) ON DELETE => cascade
#
class FareArea < ApplicationRecord
  belongs_to :fare_tier, optional: true, inverse_of: :areas
  belongs_to :fare_surcharge, optional: true, inverse_of: :areas

  validate { errors.add(:ring, "needs at least 3 corners") if Array(ring).size < 3 }

  def latlngs = Array(ring).map { |ll| ll.map(&:to_f) }
end
