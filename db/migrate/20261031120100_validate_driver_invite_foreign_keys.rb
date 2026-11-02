class ValidateDriverInviteForeignKeys < ActiveRecord::Migration[8.1]
  def change
    %i[drivers operator_drivers].each do |table|
      validate_foreign_key table, :vehicles, column: :last_vehicle_id
      validate_foreign_key table, :users, column: :display_set_by_id
    end
  end
end
