# Fleet > Drivers and Operator Drivers: the bus a past driver last drove, the company's own customer-facing name and
# photo (shown on tracking links and trip sheets instead of what the driver shared), and soft delete. A mobile number
# is unique only among drivers who are invited or active, so a declined or past driver can be invited again.
class AddInviteFieldsToDrivers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TABLES = %i[drivers operator_drivers].freeze

  def change
    TABLES.each do |table|
      add_reference table, :last_vehicle, index: { algorithm: :concurrently }
      add_foreign_key table, :vehicles, column: :last_vehicle_id, validate: false
      add_column table, :display_name, :string
      add_column table, :display_photo, :string
      add_reference table, :display_set_by, index: { algorithm: :concurrently }
      add_foreign_key table, :users, column: :display_set_by_id, validate: false
      add_column table, :display_set_at, :datetime
      add_column table, :discarded_at, :datetime

      remove_index table, %i[company_id phone], unique: true, algorithm: :concurrently
      add_index table, %i[company_id phone], unique: true, algorithm: :concurrently,
                where: "status IN ('pending', 'active') AND discarded_at IS NULL", name: "index_#{table}_on_live_phone"
      add_index table, %i[company_id status], algorithm: :concurrently, if_not_exists: true
    end
  end
end
