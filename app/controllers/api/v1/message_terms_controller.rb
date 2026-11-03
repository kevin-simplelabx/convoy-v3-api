# Convoy Admin > Message Terms: words and short forms in trip requests on WhatsApp and email, used by Fill from Message
# for every company.
module Api
  module V1
    class MessageTermsController < BaseController
      skip_before_action :assign_tenant

      def index
        authorize :platform, :index?
        order = MessageTerm::KINDS.keys
        terms = MessageTerm.includes(:created_by).to_a.sort_by { |t| [ order.index(t.kind), t.term.downcase ] }
        render json: { data: terms.map { |t| row(t) }, meta: { kinds: MessageTerm::KINDS, count: terms.size } }
      end

      def create
        authorize :platform, :create?
        term = MessageTerm.create!(term_params.merge(created_by: current_user))
        render json: { data: row(term) }, status: :created
      end

      def update
        authorize :platform, :update?
        term = MessageTerm.find(params[:id])
        term.update!(term_params)
        render json: { data: row(term) }
      end

      def destroy
        authorize :platform, :destroy?
        MessageTerm.find(params[:id]).destroy!
        head :no_content
      end

      private

      def term_params = params.expect(message_term: %i[term means kind])

      def row(t) = t.slice(:id, :term, :means, :kind, :created_at).merge(kind_label: MessageTerm::KINDS[t.kind], created_by: t.created_by&.name)
    end
  end
end
