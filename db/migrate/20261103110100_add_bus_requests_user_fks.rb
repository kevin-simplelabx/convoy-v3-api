class AddBusRequestsUserFks < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :bus_requests, :users, column: :confirmed_by_id, validate: false
    add_foreign_key :bus_requests, :users, column: :ended_by_id, validate: false
  end
end
