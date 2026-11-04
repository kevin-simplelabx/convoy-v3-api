# Validates the recorded_by key of the previous migration.
class ValidateStopPhotoSubmissionsRecordedBy < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :stop_photo_submissions, column: :recorded_by_id
  end
end
