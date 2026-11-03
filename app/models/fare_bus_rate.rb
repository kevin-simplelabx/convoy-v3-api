# School pays per bus: the rate per bill for a bus size and, when billing by booked runs, how many the school booked.
# == Schema Information
#
# Table name: fare_bus_rates
# Database name: primary
#
#  id            :bigint           not null, primary key
#  booked_runs   :integer
#  bus_type      :string           not null
#  rate          :decimal(12, 2)   not null
#  fare_table_id :bigint           not null
#
# Indexes
#
#  index_fare_bus_rates_on_fare_table_id_and_bus_type  (fare_table_id,bus_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fare_table_id => fare_tables.id) ON DELETE => cascade
#
class FareBusRate < ApplicationRecord
  belongs_to :fare_table, inverse_of: :bus_rates

  validates :bus_type, inclusion: { in: SchoolBus::BUS_TYPES.keys }

  def label = SchoolBus::BUS_TYPES.dig(bus_type, :label)
end
