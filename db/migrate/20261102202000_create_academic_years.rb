# School Bus › Year Setup: a school's academic year (12 months from its start month) with its operating days, terms or
# semesters, CCA / ASA periods, holidays and special operating days — the calendar School Bus runs follow. Setup steps
# (calendar, sessions, levels, …) lock once saved: one row per locked step in setup_locks.
class CreateAcademicYears < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_years do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.string :key, null: false
      t.integer :start_year, null: false
      t.integer :start_month, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :structure, null: false, default: "semester"
      t.integer :period_count, null: false, default: 2
      t.integer :operating_days, array: true, null: false, default: [ 1, 2, 3, 4, 5 ]
      t.boolean :cca_same_as_terms, null: false, default: true
      t.timestamps
    end
    add_index :academic_years, %i[school_id key], unique: true
    add_index :academic_years, %i[school_id starts_on ends_on]

    create_table :academic_terms do |t|
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.date :starts_on
      t.date :ends_on
      t.date :cca_starts_on
      t.date :cca_ends_on
    end
    add_index :academic_terms, %i[academic_year_id position], unique: true

    create_table :school_holidays do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.references :public_holiday, foreign_key: { on_delete: :nullify }, index: false
      t.timestamps
    end
    add_index :school_holidays, %i[academic_year_id starts_on]

    create_table :school_special_days do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.date :date, null: false
      t.string :kind, null: false
      t.integer :time
      t.string :description
      t.timestamps
    end
    add_index :school_special_days, %i[academic_year_id date]

    create_table :setup_locks do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :academic_year, foreign_key: { on_delete: :cascade }, index: false
      t.string :section, null: false
      t.timestamptz :locked_at, null: false
      t.references :locked_by, foreign_key: { to_table: :users }, index: false
    end
    add_index :setup_locks, "school_id, COALESCE(academic_year_id, 0), section", unique: true, name: "index_setup_locks_unique"
  end
end
