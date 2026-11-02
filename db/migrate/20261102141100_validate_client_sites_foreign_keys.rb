class ValidateClientSitesForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :client_sites, :schools
    validate_foreign_key :client_sites, :users
    validate_foreign_key :client_pickup_points, :users
  end
end
