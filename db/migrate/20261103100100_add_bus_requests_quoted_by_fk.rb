class AddBusRequestsQuotedByFk < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :bus_requests, :users, column: :quoted_by_id, validate: false
  end
end
