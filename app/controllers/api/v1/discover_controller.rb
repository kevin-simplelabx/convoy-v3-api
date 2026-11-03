# Convoy Admin > Discover: advertisers and placements (tabs Live / Scheduled / Draft / Ended, search, KPIs), placement
# form (picture), Pause / Resume / End now / Duplicate / Delete draft. Views, taps and sales come from the Convoy App.
module Api
  module V1
    class DiscoverController < BaseController
      skip_before_action :assign_tenant
      before_action { authorize :platform, (request.get? ? :index? : :update?) }

      PLACEMENT_FIELDS = %i[discover_advertiser_id kind kicker title subtitle background image remove_image cta price child_price seats event_on
                            pickup_points run_by_company_id bus_included sold_to_public link promo_code show_home show_discover push_once
                            starts_on ends_on slot area school_level listing_fee commission_pct status].freeze

      def advertisers
        list = DiscoverAdvertiser.kept.order(:name).to_a
        live = DiscoverPlacement.includes(:advertiser).to_a.select { |p| %w[live paused].include?(p.status_on) }.group_by(&:discover_advertiser_id)
        render json: { data: list.map { |a| advertiser_json(a, live[a.id]&.size.to_i) }, meta: { kinds: DiscoverAdvertiser::KINDS } }
      end

      def create_advertiser
        render json: { data: advertiser_json(DiscoverAdvertiser.create!(advertiser_params), 0) }, status: :created
      end

      def update_advertiser
        a = DiscoverAdvertiser.kept.find(params[:id])
        a.update!(advertiser_params)
        render json: { data: advertiser_json(a, 0) }
      end

      def destroy_advertiser
        a = DiscoverAdvertiser.kept.find(params[:id])
        raise ApplicationService::Error, "#{a.name} has placements. End or delete them first" if a.placements.any? { |p| p.status_on != "ended" }

        a.discard!
        head :no_content
      end

      # GET /discover/placements?tab=live|scheduled|draft|ended&q=
      def placements
        all = DiscoverPlacement.includes(:advertiser, :run_by_company).to_a
        tab_of = ->(p) { p.status_on == "paused" ? "live" : p.status_on }
        tab = params[:tab].presence_in(%w[live scheduled draft ended]) || "live"
        q = params[:q].to_s.downcase.strip
        list = all.select { |p| tab_of.(p) == tab && (q.empty? || [ p.title, p.kicker, p.advertiser&.name || "Convoy" ].compact.join(" ").downcase.include?(q)) }
                  .sort_by { |p| tab == "ended" ? -p.ends_on.jd : p.starts_on.jd }
        live = all.select { |p| %w[live paused].include?(p.status_on) }
        render json: { data: list.map { |p| placement_json(p) },
                       meta: { tab:, counts: %w[live scheduled draft ended].index_with { |t| all.count { |p| tab_of.(p) == t } }, kpis: kpis(all, live),
                               kinds: DiscoverPlacement::KINDS, audiences: DiscoverPlacement::AUDIENCES, areas: DiscoverPlacement::AREAS, levels: DiscoverPlacement::LEVELS } }
      end

      def placement = render(json: { data: placement_json(find_placement) })

      # POST /discover/placements (multipart with a picture) { placement: {..., audiences: []} }
      def create_placement
        p = DiscoverPlacement.new(placement_params.merge(created_by: current_user))
        apply_advertiser_terms(p)
        p.save!
        render json: { data: placement_json(p) }, status: :created
      end

      def update_placement
        p = find_placement
        p.assign_attributes(placement_params)
        apply_advertiser_terms(p) if p.discover_advertiser_id_changed?
        p.save!
        render json: { data: placement_json(p) }
      end

      def pause = act { |p| p.update!(status: "paused") }
      def resume = act { |p| p.update!(status: "live") }
      def end_now = act { |p| p.update!(ended_at: Time.current) }

      # POST /discover/placements/:id/duplicate → a draft copy ("<title> (copy)") with no views.
      def duplicate
        src = find_placement
        copy = src.dup
        copy.assign_attributes(title: "#{src.title} (copy)", status: "draft", ended_at: nil, views: 0, taps: 0, sold: 0, created_by: current_user, image: nil)
        copy.save!
        render json: { data: placement_json(copy) }, status: :created
      end

      def destroy_placement
        p = find_placement
        raise ApplicationService::Error, "Only drafts can be deleted. End it instead" unless p.draft?

        p.destroy!
        head :no_content
      end

      private

      def find_placement = DiscoverPlacement.includes(:advertiser, :run_by_company).find(params[:id])

      def act
        p = find_placement
        yield p
        render json: { data: placement_json(p.reload) }
      end

      def advertiser_params = params.expect(advertiser: %i[name kind premier country listing_fee commission_pct email])

      def placement_params
        attrs = params.expect(placement: [ *PLACEMENT_FIELDS, { audiences: [] } ])
        attrs[:discover_advertiser_id] = nil if attrs[:kind] == "news"
        attrs
      end

      # A new advertiser brings its listing fee and commission (they can be changed per placement).
      def apply_advertiser_terms(p)
        return unless p.advertiser && !params.dig(:placement, :listing_fee) && !params.dig(:placement, :commission_pct)

        p.assign_attributes(listing_fee: p.advertiser.listing_fee, commission_pct: p.advertiser.commission_pct)
      end

      def kpis(all, live)
        views = live.sum(&:views)
        taps = live.sum(&:taps)
        fees = live.sum(&:listing_fee)
        commission = live.sum(&:commission)
        { live: live.size, scheduled: all.count { |p| p.status_on == "scheduled" }, views:, taps:, tap_rate: views.positive? ? (taps * 100.0 / views).round(1) : nil,
          sold: live.sum(&:sold), revenue: fees + commission, listing_fees: fees, commission: }
      end

      def advertiser_json(a, live)
        a.slice(:id, :name, :kind, :premier, :country, :listing_fee, :commission_pct, :email).merge(kind_label: DiscoverAdvertiser::KINDS[a.kind], live_count: live)
      end

      def placement_json(p)
        p.slice(:id, *(PLACEMENT_FIELDS - %i[image remove_image status]), :audiences, :views, :taps, :sold, :ended_at, :created_at)
         .merge(status: p.status, state: p.status_on, kind_label: DiscoverPlacement::KINDS[p.kind], commission: p.commission,
                advertiser: p.advertiser && { id: p.advertiser.id, name: p.advertiser.name, premier: p.advertiser.premier },
                run_by_company: p.run_by_company && { id: p.run_by_company.id, name: p.run_by_company.name },
                image: p.image.present? ? { url: download_url(p) } : nil)
      end

      def download_url(p) = ApplicationDecorator.new(p).file_url(:image)
    end
  end
end
