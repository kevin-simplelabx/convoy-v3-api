# A tier's fares for one bus size column (after the first).
# == Schema Information
#
# Table name: fare_tier_sizes
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  fare                :decimal(12, 2)
#  one_way_fare        :decimal(12, 2)
#  period_fares        :decimal(12, 2)   default([]), not null, is an Array
#  period_pm_fares     :decimal(12, 2)   default([]), not null, is an Array
#  pm_fare             :decimal(12, 2)
#  fare_size_column_id :bigint           not null
#  fare_tier_id        :bigint           not null
#
# Indexes
#
#  index_fare_tier_sizes_on_fare_tier_id_and_fare_size_column_id  (fare_tier_id,fare_size_column_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fare_size_column_id => fare_size_columns.id) ON DELETE => cascade
#  fk_rails_...  (fare_tier_id => fare_tiers.id) ON DELETE => cascade
#
class FareTierSize < ApplicationRecord
  belongs_to :fare_tier, inverse_of: :sizes
  belongs_to :fare_size_column
end
