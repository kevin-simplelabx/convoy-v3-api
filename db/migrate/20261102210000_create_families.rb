# School Bus › Families & Riders: families (code FAM-0001, named after a parent's surname or a custom name, registered
# in the Convoy App or added here), their guardians, and which riders (by school and student ID) belong to them — one
# family per rider at a school.
class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :name_mode, null: false, default: "auto"
      t.string :source, null: false, default: "console"
      t.text :address
      t.string :postal
      t.timestamptz :registered_at
      t.boolean :sample, null: false, default: false
      t.timestamps
    end
    add_index :families, %i[company_id code], unique: true

    create_table :family_guardians do |t|
      t.references :family, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.string :first_name
      t.string :last_name
      t.string :name_order, null: false, default: "last"
      t.string :relationship, null: false, default: "Parent"
      t.string :phone
      t.string :email
      t.timestamptz :app_joined_at
      t.string :app_joined_how
      t.timestamps
    end
    add_index :family_guardians, :phone
    add_index :family_guardians, :email

    create_table :family_riders do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :family, null: false, foreign_key: { on_delete: :cascade }
      t.references :school, null: false, foreign_key: true, index: false
      t.string :rid, null: false
      t.timestamptz :applied_at
      t.timestamptz :accepted_at
      t.timestamps
    end
    add_index :family_riders, %i[school_id rid], unique: true
  end
end
