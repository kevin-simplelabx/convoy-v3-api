# Shared by DriverDecorator and OperatorDriverDecorator.
module InvitedDriverDecorator
  def photo_info = file_info(:photo, versions: [ :thumb ])

  # Thumbnail link for the Scheduler (grid rows and drawer), nil without a photo.
  def photo_thumb = file_url(:photo, :thumb)

  # Shown to Your Customers: { name, photo, set_by, set_at } or nil when the company has not set one.
  def display_info
    return unless display_set_at

    { name: display_name, photo: file_info(:display_photo, versions: [ :thumb ]), set_by: display_set_by&.name, set_at: display_set_at }
  end

  # Date shown in the tab's third column: invited (pending), answered (declined) or left (past).
  def status_on
    pending? ? invited_at : responded_at
  end
end
