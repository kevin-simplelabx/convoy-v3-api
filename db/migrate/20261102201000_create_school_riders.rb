# School Bus › Rider Data: a school's rider list uploaded as a file, used from its Effective From date until a later
# list (the latest one on or before a date is in use), and the riders in it — plus riders added by hand, who belong
# to no list and count on every date between their start and end. Homes are placed by OneMap in the background.
class CreateSchoolRiders < ActiveRecord::Migration[8.1]
  def change
    create_table :rider_datasets do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.date :effective_from, null: false
      t.string :file
      t.string :file_name, null: false
      t.integer :riders_count, null: false, default: 0
      t.integer :unlocated_count, null: false, default: 0
      t.string :status, null: false, default: "locating"
      t.references :uploaded_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :rider_datasets, %i[school_id effective_from]

    create_table :school_riders do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :rider_dataset, foreign_key: { on_delete: :cascade }, index: false
      t.string :rid, null: false
      t.string :first_name
      t.string :last_name
      t.string :name_order, null: false, default: "last"
      t.string :name, null: false
      t.string :gender
      t.string :grade
      t.string :address
      t.string :postal, null: false
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.boolean :am, null: false, default: true
      t.boolean :pm, null: false, default: true
      t.integer :cca_days, array: true, null: false, default: []
      t.date :starts_on
      t.date :ends_on
      t.string :parent_name
      t.string :parent_contact
      t.text :remarks
      t.string :source, null: false, default: "csv"
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :school_riders, %i[rider_dataset_id rid], unique: true, where: "rider_dataset_id IS NOT NULL"
    add_index :school_riders, %i[school_id rid], unique: true, where: "rider_dataset_id IS NULL", name: "index_school_riders_manual_rid"
    add_index :school_riders, %i[school_id rider_dataset_id]
    add_index :school_riders, :postal
  end
end
