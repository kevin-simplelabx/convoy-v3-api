class StopPointDecorator < ApplicationDecorator
  def photo_info = file_info(:photo, versions: [ :thumb ])
  def photo_original_info = file_info(:photo_original)
end
