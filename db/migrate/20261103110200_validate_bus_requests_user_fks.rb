class ValidateBusRequestsUserFks < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :bus_requests, :users, column: :confirmed_by_id
    validate_foreign_key :bus_requests, :users, column: :ended_by_id
  end
end
