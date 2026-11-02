# == Schema Information
#
# Table name: trip_price_cells
# Database name: primary
#
#  id          :bigint           not null, primary key
#  amount      :decimal(12, 2)   not null
#  direction   :integer
#  slot_no     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  trip_id     :bigint           not null
#  trip_run_id :bigint
#
# Indexes
#
#  index_trip_price_cells_on_company_id   (company_id)
#  index_trip_price_cells_on_trip_id      (trip_id)
#  index_trip_price_cells_on_trip_run_id  (trip_run_id)
#  index_trip_price_cells_one_per_cell    (trip_id, COALESCE(direction, 0), COALESCE(trip_run_id, (0)::bigint), COALESCE(slot_no, 0)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#
# A cell of a shuttle's price table. Row: all runs (direction and run empty), a direction, or one run.
# Column: the whole route (slot empty) or one vehicle slot. Written from the form as {row: "all"|"d1"|"d1r0", col: "all"|"1"}.
class TripPriceCell < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip
  belongs_to :trip_run, optional: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  def row_key = trip_run ? trip_run.key : (direction ? "d#{direction}" : "all")
  def col_key = slot_no ? slot_no.to_s : "all"
end
