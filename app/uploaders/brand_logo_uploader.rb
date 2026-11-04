# A client's logo for the Client Portal strip: PNG, JPG or WebP up to 1 MB, kept as sent (no SVG: files are served
# inline, and an SVG can carry script). Its width / height ratio sizes the strip.
class BrandLogoUploader < ApplicationUploader
  def extension_allowlist = %w[png jpg jpeg webp]
  def content_type_allowlist = [ %r{\Aimage/(png|jpeg|webp)\z} ]
  def size_range = 1.byte..1.megabyte

  def self.ratio(uploader)
    image = MiniMagick::Image.open(uploader.file.path)
    (image.width.to_d / image.height).round(2).clamp(0.2, 20)
  end
end
