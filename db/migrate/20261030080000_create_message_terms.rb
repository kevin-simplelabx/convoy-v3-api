class CreateMessageTerms < ActiveRecord::Migration[8.1]
  def change
    # Words and short forms Fill from Message reads with every message (Combi = 13-seater minibus). Platform-wide, kept by Convoy.
    create_table :message_terms do |t|
      t.string :term, null: false
      t.text   :means, null: false
      t.string :kind, null: false, default: "oth"     # veh (vehicle) | svc (service) | place | oth
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :message_terms, "LOWER(term)", unique: true, name: "index_message_terms_on_lower_term"
  end
end
