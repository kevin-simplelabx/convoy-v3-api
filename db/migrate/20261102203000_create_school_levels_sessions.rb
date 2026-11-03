# School Bus › Year Setup: the levels a school offers (in order, the final ones graduate), the bus sessions of an
# academic year (to school, to home, CCA / ASA; times, days and day variants) and which buses need a bus attendant.
class CreateSchoolLevelsSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :school_levels do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.integer :position, null: false
      t.string :name, null: false
      t.string :section, null: false, default: "custom"
      t.boolean :final, null: false, default: false
      t.timestamps
    end
    add_index :school_levels, "school_id, lower(name)", unique: true, name: "index_school_levels_unique_name"

    create_table :bus_sessions do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.string :name, null: false
      t.string :direction, null: false
      t.boolean :cca, null: false, default: false
      t.string :service, null: false, default: "d2d"
      t.integer :max_journey_minutes, null: false, default: 60
      t.integer :days, array: true, null: false, default: []
      t.integer :arrive_from
      t.integer :arrive_to
      t.integer :dismissal
      t.integer :depart
      t.text :notes
      t.timestamps
    end
    add_index :bus_sessions, %i[academic_year_id position]

    create_table :bus_session_variants do |t|
      t.references :bus_session, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.integer :days, array: true, null: false, default: []
      t.integer :arrive_from
      t.integer :arrive_to
      t.integer :dismissal
      t.integer :depart
    end
    add_index :bus_session_variants, %i[bus_session_id position]

    create_table :school_attendant_policies do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: { unique: true }
      t.string :needs, null: false, default: "statutory"
      t.string :sizes, array: true, null: false, default: []
      t.string :provided_by, null: false, default: "operator"
      t.timestamps
    end
  end
end
