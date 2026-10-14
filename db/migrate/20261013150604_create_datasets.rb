class CreateDatasets < ActiveRecord::Migration[8.1]
  def change
    create_table :datasets do |t|
      t.references :school, null: false, foreign_key: true
      t.date   :effective_from, null: false
      t.string :file_name,  default: "upload.csv"
      t.string :uploaded_by, default: ""
      t.jsonb  :rows, default: []

      t.timestamps
    end

    add_index :datasets, [ :school_id, :effective_from ], name: "index_datasets_on_school_and_date"
  end
end
