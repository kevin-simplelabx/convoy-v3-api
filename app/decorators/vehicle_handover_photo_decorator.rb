class VehicleHandoverPhotoDecorator < ApplicationDecorator
  def photo_info = file_info(:photo, versions: [ :thumb ])
  def marked_photo_info = file_info(:marked_photo, versions: [ :thumb ])
end
