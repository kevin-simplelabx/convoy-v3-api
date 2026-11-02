class PayRewardBlueprint < ApplicationBlueprint
  fields :title, :description, :points_required, :status

  field(:photo) { |r| r.photo_info }
end
