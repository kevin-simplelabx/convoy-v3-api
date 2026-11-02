# HR > Salary Simulator > Templates: five shared slots holding a made-up month (jobs, school routes, school holidays,
# scheme and vehicle type) for testing pay schemes. The month's jobs are a snapshot the simulator loads back whole,
# so they are kept as jsonb.
class CreatePaySimulatorTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :pay_simulator_templates do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.integer :slot, null: false
      t.string :name, null: false
      t.text :description
      t.date :month, null: false
      t.references :pay_scheme, foreign_key: true
      t.references :vehicle_type, foreign_key: true
      t.integer :rejected, null: false, default: 0
      t.integer :on_time_percent
      t.integer :attendance_percent
      t.date :school_holidays_from
      t.date :school_holidays_to
      t.jsonb :routes, null: false, default: []
      t.jsonb :jobs, null: false, default: {}
      t.references :saved_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :pay_simulator_templates, %i[company_id slot], unique: true
    add_check_constraint :pay_simulator_templates, "slot BETWEEN 1 AND 5", name: "pay_simulator_templates_slot"
  end
end
