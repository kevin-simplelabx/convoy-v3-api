# Trips > Rate Cards: list, view, new (the standard starting card), create, edit, Make Default, Archive / Unarchive,
# warnings while editing; and Price From Rate Card (Corporate Shuttle in the trip form).
module Api
  module V1
    class RateCardsController < BaseController
      INCLUDES = [ :vehicle_types, :amounts, :distance_bands, { periods: %i[ranges rates] } ].freeze

      # Default card first, then active cards, then archived, by name.
      def index
        authorize RateCard
        cards = policy_scope(RateCard).includes(:vehicle_types, :periods)
                                      .order(default_card: :desc, archived_at: :desc, name: :asc).to_a
        render json: { data: RateCardBlueprint.render_as_hash(cards, client_counts: client_counts(cards)) }
      end

      def show
        render_card authorize(find)
      end

      # GET /rate_cards/new — the standard starting card, not saved (fields as in show).
      def new
        authorize RateCard, :create?
        params_hash = RateCards::Standard.params
        form = RateCards::Form.new(RateCard.new, params_hash).build
        render json: { data: params_hash.merge(warnings: RateCards::Check.call(form.card)) }
      end

      def create
        card = RateCards::Save.call(card: authorize(RateCard.new), params: card_params)
        render_card card, status: :created
      end

      # PATCH { rate_card: {...whole card}, lock_version }
      def update
        card = RateCards::Save.call(card: authorize(find), params: card_params, lock_version: params[:lock_version])
        render_card card
      end

      # POST /rate_cards/check { rate_card: {...} } — overlaps and gaps while editing; nothing is saved.
      def check
        authorize RateCard
        form = RateCards::Form.new(RateCard.new, card_params).build
        render json: { data: RateCards::Check.call(form.card).merge(errors: form.errors) }
      end

      def make_default = change_state(:make_default)
      def archive = change_state(:archive)
      def unarchive = change_state(:unarchive)

      # POST /rate_cards/quote { client_id, date, start_time, vehicle_type_id, km, extra_stops }
      def quote
        authorize RateCard
        q = params.permit(:client_id, :date, :start_time, :vehicle_type_id, :km, :extra_stops)
        result = RateCards::Quote.call(
          client: q[:client_id].presence && Client.kept.find(q[:client_id]), date: Date.parse(q.require(:date)),
          start_time: q.require(:start_time), vehicle_type: VehicleType.find(q.require(:vehicle_type_id)),
          km: q[:km].presence, extra_stops: q[:extra_stops]
        )
        render json: { data: { card: result.card&.slice(:id, :name), amount: result.amount, missing: result.missing,
                               lines: result.lines.map(&:to_h) } }
      end

      private

      def find = policy_scope(RateCard).includes(*INCLUDES).find(params[:id])
      def card_params = params.require(:rate_card).permit(*RateCards::Form::PERMIT)

      def change_state(action)
        card = authorize find, :"#{action}?"
        render_card RateCards::ChangeState.call(card:, action:)
      end

      def render_card(card, status: :ok)
        card = policy_scope(RateCard).includes(*INCLUDES).find(card.id)
        render json: { data: RateCardBlueprint.render_as_hash(card, view: :full, client_counts: client_counts([ card ])) }, status:
      end

      # Clients per card: assigned to an active card, else the default card's.
      def client_counts(cards)
        assigned = Client.kept.joins(:rate_card).merge(RateCard.active).group(:rate_card_id).count
        default = cards.find(&:default_card?) || RateCard.active.find_by(default_card: true)
        unassigned = Client.kept.count - assigned.values.sum
        default ? assigned.merge(default.id => assigned.fetch(default.id, 0) + unassigned) : assigned
      end
    end
  end
end
