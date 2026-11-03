# A bus size column of a fare table (Price Differs by Bus Size): buses up to max_seats (the last column: above the one
# before). The first column holds the tier's own fares; the others are fare_tier_sizes.
# == Schema Information
#
# Table name: fare_size_columns
# Database name: primary
#
#  id            :bigint           not null, primary key
#  max_seats     :integer
#  position      :integer          not null
#  fare_table_id :bigint           not null
#
# Indexes
#
#  index_fare_size_columns_on_fare_table_id_and_position  (fare_table_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (fare_table_id => fare_tables.id) ON DELETE => cascade
#
class FareSizeColumn < ApplicationRecord
  belongs_to :fare_table, inverse_of: :size_columns
end
