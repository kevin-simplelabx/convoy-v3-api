class UserDecorator < ApplicationDecorator
  def initials
    shown_name.to_s.split.first(2).map { |w| w[0] }.join.upcase
  end

  def avatar_info
    file_info(:avatar, versions: [ :thumb ])
  end

  def can_be_edited_by?(actor)
    return false unless actor && !actor.convoy_admin? && actor.can?(:users)

    !owner? || actor.owner?
  end
end
