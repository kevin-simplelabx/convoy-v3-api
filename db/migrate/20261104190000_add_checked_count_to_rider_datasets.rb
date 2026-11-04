# Rider import: how many riders of the list OneMap has been asked about so far ("Finding addresses on OneMap: i of t").
class AddCheckedCountToRiderDatasets < ActiveRecord::Migration[8.1]
  def up
    add_column :rider_datasets, :checked_count, :integer, null: false, default: 0
    # safety_assured: one-off backfill on a small table (a few rider lists per school): lists already located were all checked.
    safety_assured { execute "UPDATE rider_datasets SET checked_count = riders_count WHERE status = 'ready'" }
  end

  def down
    remove_column :rider_datasets, :checked_count
  end
end
