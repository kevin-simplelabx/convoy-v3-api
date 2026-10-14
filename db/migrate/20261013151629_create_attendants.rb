class CreateAttendants < ActiveRecord::Migration[8.1]
  def change
    create_table :attendants do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :contact
      t.string :notes

      t.timestamps
    end
  end
end
