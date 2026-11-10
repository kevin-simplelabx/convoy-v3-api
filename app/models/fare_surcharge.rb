# A location surcharge on top of the tier fare for homes in some postal sectors or drawn areas: an extra amount a
# year (flat), an extra % or a fixed annual fare; 1-way riders pay the same, a % of the 2-way charge, or a fixed amount.
# == Schema Information
#
# Table name: fare_surcharges
# Database name: primary
#
#  id            :bigint           not null, primary key
#  amount        :decimal(12, 2)
#  kind          :string           default("flat"), not null
#  name          :string           not null
#  one_way_kind  :string           default("same"), not null
#  one_way_value :decimal(12, 2)
#  position      :integer          not null
#  sectors       :string           default([]), not null, is an Array
#  fare_table_id :bigint           not null
#
# Indexes
#
#  index_fare_surcharges_on_fare_table_id_and_position  (fare_table_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (fare_table_id => fare_tables.id) ON DELETE => cascade
#
class FareSurcharge < ApplicationRecord
  self.ignored_columns += [ "area" ] # moved to fare_areas (20261105100200); dropped later

  belongs_to :fare_table, inverse_of: :surcharges
  has_many :areas, -> { order(:position) }, class_name: "FareArea", dependent: :delete_all, inverse_of: :fare_surcharge

  validates :kind, inclusion: { in: %w[flat pct fixed] }
  validates :one_way_kind, inclusion: { in: %w[same pct fixed] }
end
