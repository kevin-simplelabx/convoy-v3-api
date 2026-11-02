# Companies opened before Company Settings had their country set by Convoy when the account was opened.
class BackfillCompaniesCountrySetAt < ActiveRecord::Migration[8.1]
  def up
    # safety_assured: companies is a small platform table (one row per transport company)
    safety_assured { execute "UPDATE companies SET country_set_at = created_at WHERE country_set_at IS NULL" }
  end

  def down; end
end
