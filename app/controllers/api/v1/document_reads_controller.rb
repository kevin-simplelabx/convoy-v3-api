# Read a file or a message with Claude in the background: POST returns 202 with the read; poll GET until done or failed.
module Api
  module V1
    class DocumentReadsController < BaseController
      def create
        read = authorize DocumentRead.new(params.permit(:kind, :file, :input_text).merge(user: current_user))
        read.save!
        render_data read, DocumentReadBlueprint, status: :accepted
      end

      def show
        render_data authorize(policy_scope(DocumentRead).find(params[:id])), DocumentReadBlueprint
      end
    end
  end
end
