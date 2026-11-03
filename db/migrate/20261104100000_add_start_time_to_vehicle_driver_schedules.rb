# A default driver from a time of day, not only a date (a driver switches buses at 06:30): runs on the bus starting from
# then take the new driver. 0 = the whole day (as before). One entry per bus, date and time.
class AddStartTimeToVehicleDriverSchedules < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :vehicle_driver_schedules, :start_time, :integer, null: false, default: 0
    add_index :vehicle_driver_schedules, %i[vehicle_id starts_on start_time], unique: true, algorithm: :concurrently,
                                                                               name: "index_vehicle_driver_schedules_on_vehicle_date_time"
    remove_index :vehicle_driver_schedules, %i[vehicle_id starts_on], unique: true, algorithm: :concurrently,
                                                                      name: "index_vehicle_driver_schedules_on_vehicle_id_and_starts_on"
  end
end
