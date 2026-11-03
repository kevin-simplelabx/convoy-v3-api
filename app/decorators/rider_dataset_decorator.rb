class RiderDatasetDecorator < ApplicationDecorator
  def file_download = file_info(:file)
end
