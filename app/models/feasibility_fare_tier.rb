# A fare tier of a feasibility study: up to max_km from the school (the last is open-ended), monthly 2-way and 1-way fares.
# == Schema Information
#
# Table name: feasibility_fare_tiers
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  fare                 :decimal(12, 2)
#  max_km               :decimal(6, 2)
#  one_way_fare         :decimal(12, 2)
#  position             :integer          not null
#  feasibility_study_id :bigint           not null
#
# Indexes
#
#  idx_on_feasibility_study_id_position_e835660dba  (feasibility_study_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (feasibility_study_id => feasibility_studies.id) ON DELETE => cascade
#
class FeasibilityFareTier < ApplicationRecord
  belongs_to :feasibility_study, inverse_of: :fare_tiers
end
