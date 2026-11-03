# A feasibility study's monthly price for a bus size and the attendant add-on.
# == Schema Information
#
# Table name: feasibility_bus_prices
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  attendant            :decimal(12, 2)
#  bus_type             :string           not null
#  monthly              :decimal(12, 2)
#  feasibility_study_id :bigint           not null
#
# Indexes
#
#  idx_on_feasibility_study_id_bus_type_f4b637ec38  (feasibility_study_id,bus_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (feasibility_study_id => feasibility_studies.id) ON DELETE => cascade
#
class FeasibilityBusPrice < ApplicationRecord
  belongs_to :feasibility_study, inverse_of: :bus_prices
end
