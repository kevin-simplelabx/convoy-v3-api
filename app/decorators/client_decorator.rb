class ClientDecorator < ApplicationDecorator
  # Client Portal strip: logo (signed link) with its width / height ratio, and the colour line.
  def brand_info
    { logo: file_info(:brand_logo), logo_ratio: brand_logo_ratio&.to_f, color: brand_color }
  end
end
