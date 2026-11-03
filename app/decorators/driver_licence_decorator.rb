class DriverLicenceDecorator < ApplicationDecorator
  def card_front_info = file_info(:card_front, versions: [ :thumb ])
  def card_back_info = file_info(:card_back, versions: [ :thumb ])
end
