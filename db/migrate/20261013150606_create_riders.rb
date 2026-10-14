class CreateRiders < ActiveRecord::Migration[8.1]
  def change
    create_table :riders do |t|
      t.references :school, null: false, foreign_key: true
      t.string  :rid
      t.string  :name,           null: false
      t.string  :gender,         default: ""
      t.string  :grade,          default: ""
      t.string  :address,        default: ""
      t.string  :postal,         default: ""
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.boolean :am,             default: true
      t.boolean :pm,             default: true
      t.string  :cca,            default: ""
      t.date    :start_date
      t.date    :end_date
      t.string  :parent_name,    default: ""
      t.string  :parent_contact, default: ""
      t.string  :remarks,        default: ""

      t.timestamps
    end

  end
end
