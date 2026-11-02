# HR > Rewards photo: JPEG, PNG or WebP under 2 MB, kept at most 480 px (as the prototype shows it in the driver app).
class RewardPhotoUploader < ImageUploader
  process resize_to_limit: [ 480, 480 ]

  def extension_allowlist = %w[jpg jpeg png webp]
  def size_range = 1.byte..2.megabytes
end
