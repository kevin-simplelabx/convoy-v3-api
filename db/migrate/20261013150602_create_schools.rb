class CreateSchools < ActiveRecord::Migration[8.1]
  def change
    create_table :schools do |t|
      t.references :company, null: false, foreign_key: true
      t.string  :name,    null: false
      t.string  :short,   default: ""
      t.string  :address, default: ""
      t.string  :postal,  default: ""
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.jsonb   :labels, default: {}

      t.timestamps
    end

  end
end
