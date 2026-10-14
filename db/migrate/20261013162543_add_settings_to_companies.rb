class AddSettingsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :settings, :jsonb
  end
end
