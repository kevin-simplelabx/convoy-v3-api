class AttendantDecorator < ApplicationDecorator
  def photo_info = file_info(:photo, versions: [ :thumb ])
  def photo_thumb = file_url(:photo, :thumb)
end
