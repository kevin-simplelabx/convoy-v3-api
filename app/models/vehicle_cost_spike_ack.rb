# Vehicle Financials > Cost Spikes: a spike (vehicle, category, month) marked as checked.
# == Schema Information
#
# Table name: vehicle_cost_spike_acks
# Database name: primary
#
#  id            :bigint           not null, primary key
#  category      :string           not null
#  month         :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  checked_by_id :bigint
#  company_id    :bigint           not null
#  vehicle_id    :bigint           not null
#
# Indexes
#
#  index_vehicle_cost_spike_acks_on_checked_by_id  (checked_by_id)
#  index_vehicle_cost_spike_acks_unique            (vehicle_id,category,month) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (checked_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleCostSpikeAck < ApplicationRecord
  include TenantScoped

  belongs_to :vehicle
  belongs_to :checked_by, class_name: "User", optional: true
end
