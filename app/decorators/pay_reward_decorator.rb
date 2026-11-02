class PayRewardDecorator < ApplicationDecorator
  def photo_info = file_info(:photo, versions: [ :thumb ])
end
