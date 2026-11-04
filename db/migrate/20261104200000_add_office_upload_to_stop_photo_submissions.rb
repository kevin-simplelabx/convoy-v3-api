# Photo requests › Add Received Photos: the office records photos it received (until the Convoy App sends them):
# source office / app, who recorded it, and "photo n of m" of the batch it came in.
class AddOfficeUploadToStopPhotoSubmissions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :stop_photo_submissions, :source, :string, null: false, default: "app"
    add_column :stop_photo_submissions, :batch_index, :integer
    add_column :stop_photo_submissions, :batch_size, :integer
    add_reference :stop_photo_submissions, :recorded_by, index: { algorithm: :concurrently }
    add_foreign_key :stop_photo_submissions, :users, column: :recorded_by_id, validate: false
  end
end
