class DriverNoticeDecorator < ApplicationDecorator
  def image_info = file_info(:image, versions: [ :thumb ])
end
