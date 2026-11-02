class ValidateClientsRateCardFk < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :clients, :rate_cards
  end
end
