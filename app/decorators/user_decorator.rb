class UserDecorator < ApplicationDecorator
  def initials
    name.to_s.split.first(2).map { |w| w[0] }.join.upcase
  end

  def avatar_info
    file_info(:avatar, versions: [ :thumb ])
  end
end
