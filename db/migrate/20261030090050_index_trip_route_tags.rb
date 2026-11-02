class IndexTripRouteTags < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :trips, :route_tags, using: :gin, algorithm: :concurrently
  end
end
