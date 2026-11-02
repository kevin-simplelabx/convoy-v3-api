# Settings > Users > Schools: the schools a user who is not on All Schools can open.
class CreateUserSchools < ActiveRecord::Migration[8.1]
  def change
    create_table :user_schools do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true
      t.timestamps
    end
    add_index :user_schools, %i[user_id school_id], unique: true
  end
end
