# How many points of a deduction came from which lot.
# == Schema Information
#
# Table name: driver_point_allocations
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  points                    :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  driver_point_deduction_id :bigint           not null
#  driver_point_lot_id       :bigint           not null
#
# Indexes
#
#  index_driver_point_allocations_on_driver_point_deduction_id  (driver_point_deduction_id)
#  index_driver_point_allocations_on_driver_point_lot_id        (driver_point_lot_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_point_deduction_id => driver_point_deductions.id)
#  fk_rails_...  (driver_point_lot_id => driver_point_lots.id)
#
class DriverPointAllocation < ApplicationRecord
  belongs_to :driver_point_deduction
  belongs_to :driver_point_lot
end
