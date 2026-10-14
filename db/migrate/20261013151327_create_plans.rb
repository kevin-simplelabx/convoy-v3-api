class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :school, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :data, null: false, default: []

      t.timestamps
    end
  end
end
