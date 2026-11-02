class ApplicationDecorator < Draper::Decorator
  delegate_all

  # Signed, expiring link to a CarrierWave file (files are private; see DownloadsController).
  def file_url(mount, version = nil)
    uploader = object.public_send(mount)
    return nil if uploader.blank?

    token = Download.token_for(object, mount, version)
    Rails.application.routes.url_helpers.api_v1_download_path(token)
  end

  # { url, thumb_url, name, size, content_type } for an image or document mount.
  def file_info(mount, versions: [])
    uploader = object.public_send(mount)
    return nil if uploader.blank?

    { url: file_url(mount), name: uploader.file&.filename, size: uploader.size, content_type: uploader.content_type }
      .merge(versions.to_h { |v| [ :"#{v}_url", file_url(mount, v) ] })
  end
end
