class AddRateCardToClients < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # The card a client uses (else the company's default).
  def change
    add_reference :clients, :rate_card, index: { algorithm: :concurrently }
    add_foreign_key :clients, :rate_cards, validate: false
  end
end
