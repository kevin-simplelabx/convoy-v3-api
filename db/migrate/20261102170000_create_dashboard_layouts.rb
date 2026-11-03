# Dashboard: each user's layout (pages, and each widget's place and size on the grid). A snapshot of the screen,
# read and written whole, never queried by its parts, so it is jsonb.
class CreateDashboardLayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboard_layouts do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.jsonb :pages, null: false, default: []
      t.timestamps
    end
    add_index :dashboard_layouts, %i[user_id company_id], unique: true
  end
end
