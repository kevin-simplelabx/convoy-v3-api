class ValidateBusRequestsQuotedByFk < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :bus_requests, :users, column: :quoted_by_id
  end
end
