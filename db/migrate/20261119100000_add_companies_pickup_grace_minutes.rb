# Convoy Driver app parity (19/11/2026): at a pick-up point the app waits for every child expected there until the
# planned time plus this many minutes before it lets the driver leave (Company Settings; the design's default is 2).
class AddCompaniesPickupGraceMinutes < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :pickup_grace_minutes, :integer, default: 2, null: false
  end
end
