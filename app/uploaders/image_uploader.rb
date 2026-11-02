# Photos (vehicles, stops, standby areas, avatars, logos): resized to 1280 px, with a 320 px thumb.
class ImageUploader < ApplicationUploader
  include CarrierWave::MiniMagick

  process resize_to_limit: [ 1280, 1280 ]

  version :thumb do
    process resize_to_fill: [ 320, 320 ]
  end

  def extension_allowlist
    %w[jpg jpeg png webp heic]
  end

  def content_type_allowlist
    [ %r{image/} ]
  end
end
