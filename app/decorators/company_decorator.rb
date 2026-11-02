class CompanyDecorator < ApplicationDecorator
  def display_name
    short_name.presence || name
  end

  def logo_info
    file_info(:logo, versions: [ :thumb ])
  end
end
