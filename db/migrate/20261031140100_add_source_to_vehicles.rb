# How a vehicle was added: console (a user) or share_form (filled in by the hired driver, then added by a user).
class AddSourceToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :source, :string, null: false, default: "console"
  end
end
