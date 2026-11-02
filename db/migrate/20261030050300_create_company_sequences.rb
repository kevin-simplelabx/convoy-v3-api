class CreateCompanySequences < ActiveRecord::Migration[8.1]
  def change
    # Running numbers per company: client codes (CL00001), trip numbers, booking IDs...
    create_table :company_sequences do |t|
      t.references :company, null: false, foreign_key: true
      t.string  :name, null: false
      t.bigint  :value, null: false, default: 0
      t.timestamps
    end
    add_index :company_sequences, %i[company_id name], unique: true
  end
end
