class CreateStopLibraries < ActiveRecord::Migration[8.1]
  def change
    create_table :stop_libraries do |t|
      t.references :company, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :lib,      null: false, default: []
      t.jsonb :counters, null: false, default: {}

      t.timestamps
    end
  end
end
