class OccurrenceDisposalDecorator < ApplicationDecorator
  def start_photo_info = file_info(:start_photo, versions: [ :thumb ])
  def end_photo_info = file_info(:end_photo, versions: [ :thumb ])
  def release_signature_info = file_info(:release_signature)
end
