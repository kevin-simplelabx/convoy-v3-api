# Base uploader: private disk storage under storage/<model>/<mount>/<id>, served only through
# authorised API endpoints (never a public URL).
class ApplicationUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "#{model.class.name.underscore}/#{mounted_as}/#{model.id}"
  end

  def size_range
    1.byte..10.megabytes
  end
end
