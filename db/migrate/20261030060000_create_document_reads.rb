class CreateDocumentReads < ActiveRecord::Migration[8.1]
  def change
    # A file or text sent to Claude to be read (log card, insurance paper, workshop invoice, route list, trip message).
    # The reply is kept as the model gave it (a snapshot, not queried), the file can then be attached to a record.
    create_table :document_reads do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string   :kind, null: false               # log_card | insurance | maintenance_invoice | route_list | trip_message
      t.string   :file                            # CarrierWave (DocumentUploader); empty for a pasted message
      t.text     :input_text
      t.string   :status, null: false, default: "pending" # pending | done | failed
      t.jsonb    :result
      t.text     :error
      t.string   :model
      t.integer  :input_tokens
      t.integer  :output_tokens
      t.datetime :finished_at
      t.timestamps
    end
    add_index :document_reads, %i[company_id kind created_at]
  end
end
