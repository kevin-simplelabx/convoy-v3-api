class CreateTripTimeChanges < ActiveRecord::Migration[8.1]
  def change
    # Every Run From This Date: a recurring trip's times move by `minutes` from a date on (latest from <= date wins).
    create_table :trip_time_changes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.date    :effective_from, null: false
      t.integer :minutes, null: false
      t.references :trip_run, foreign_key: true               # a shuttle run only (else every run)
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :trip_time_changes, %i[trip_id effective_from]
  end
end
