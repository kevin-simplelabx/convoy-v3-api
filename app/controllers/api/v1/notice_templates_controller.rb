# Notices > Templates: the usual wording, picked in the Notice form ({min} and {time} are filled in there).
module Api
  module V1
    class NoticeTemplatesController < BaseController
      def index
        authorize NoticeTemplate
        render json: { data: policy_scope(NoticeTemplate).order(:id).map { |t| present_template(t) } }
      end

      # POST { notice_template: { name, message } } — Add Template: both optional ("New Template", empty message).
      def create
        attrs = template_params
        template = authorize NoticeTemplate.new(name: attrs[:name].presence || NoticeTemplate.next_default_name, message: attrs[:message].to_s)
        template.save!
        render json: { data: present_template(template) }, status: :created
      end

      def update
        template = authorize policy_scope(NoticeTemplate).find(params[:id])
        template.update!(template_params)
        render json: { data: present_template(template) }
      end

      # The last template can't be removed. Notices made from it keep their message.
      def destroy
        authorize(policy_scope(NoticeTemplate).find(params[:id])).destroy!
        head :no_content
      end

      private

      def template_params = params.fetch(:notice_template, {}).permit(:name, :message)
      def present_template(template) = template.slice(:id, :name, :message)
    end
  end
end
