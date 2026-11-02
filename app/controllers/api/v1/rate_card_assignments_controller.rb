# Trips > Rate Cards > Client Rate Cards: which card each client is priced by (assigned, else the default card).
module Api
  module V1
    class RateCardAssignmentsController < BaseController
      # GET /rate_card_assignments?q=&kind=&rate_card_id= — meta.cards: active cards with their client counts.
      def index
        authorize RateCard
        default = RateCard.active.find_by(default_card: true)
        clients = policy_scope(Client).kept.includes(:rate_card).order(:name)
        clients = clients.where(kind: params[:kind]) if params[:kind].present?
        clients = search(clients, params[:q])
        clients = on_card(clients, params[:rate_card_id].to_i, default) if params[:rate_card_id].present?
        pagy, records = pagy(clients)
        render json: { data: records.map { |c| row(c, default) },
                       meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, cards: cards(default) } }
      end

      # PATCH /rate_card_assignments/:client_id { rate_card_id } — picking the default card clears the assignment.
      def update
        authorize RateCard, :update?
        client = policy_scope(Client).kept.find(params[:client_id])
        card = RateCard.active.find(params.require(:rate_card_id))
        client.update!(rate_card: card.default_card? ? nil : card)
        render json: { data: row(client.reload, RateCard.active.find_by(default_card: true)) }
      end

      private

      def search(scope, q)
        return scope if q.blank?

        like = "%#{Client.sanitize_sql_like(q.strip)}%"
        scope.where("clients.name ILIKE :q OR clients.code ILIKE :q OR clients.email ILIKE :q OR clients.uen ILIKE :q", q: like)
      end

      def on_card(scope, card_id, default)
        return scope.where(rate_card_id: card_id) unless card_id == default&.id

        scope.left_joins(:rate_card).where("clients.rate_card_id IS NULL OR clients.rate_card_id = :id OR rate_cards.archived_at IS NOT NULL", id: card_id)
      end

      def row(client, default)
        assigned = client.rate_card && !client.rate_card.archived? ? client.rate_card : nil
        card = assigned || default
        { id: client.id, name: client.name, code: client.code, kind: client.kind, email: client.email,
          rate_card_id: card&.id, rate_card_name: card&.name, on_default: assigned.nil? || assigned.default_card? }
      end

      def cards(default)
        assigned = Client.kept.joins(:rate_card).merge(RateCard.active).group(:rate_card_id).count
        unassigned = Client.kept.count - assigned.values.sum
        RateCard.active.order(default_card: :desc, name: :asc).map do |c|
          { id: c.id, name: c.name, default_card: c.default_card, clients_count: assigned.fetch(c.id, 0) + (c.id == default&.id ? unassigned : 0) }
        end
      end
    end
  end
end
