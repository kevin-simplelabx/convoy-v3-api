# Serves private CarrierWave files behind a signed, expiring token (see Download); the link needs no Bearer header.
module Api
  module V1
    class DownloadsController < BaseController
      skip_before_action :authenticate!
      skip_after_action :verify_authorized

      def show
        file = Download.resolve(params[:token])
        raise ActiveRecord::RecordNotFound if file.blank? || file.path.blank? || !File.exist?(file.path)

        send_file file.path, type: file.content_type, disposition: :inline, filename: file.file.filename
      end
    end
  end
end
