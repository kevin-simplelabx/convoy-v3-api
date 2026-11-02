class FuelEntryDecorator < ApplicationDecorator
  def receipt_info = file_info(:receipt)
end
