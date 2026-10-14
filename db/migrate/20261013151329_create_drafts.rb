class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts do |t|
      t.references :school, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :data, default: nil

      t.timestamps
    end
  end
end
