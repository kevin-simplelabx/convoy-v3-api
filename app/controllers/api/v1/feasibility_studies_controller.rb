# School Bus › Feasibility Studies: studies (school or prospect, pick-up, walk, bus prices, fare tiers), students pasted by
# postal code (each found on OneMap in the background; Check Again), scenarios (add / copy / change / delete / run in the
# background) with their cost and fares, Use Suggested Fares, and a school's real fare table as tiers.
module Api
  module V1
    class FeasibilityStudiesController < BaseController
      INCLUDES = [ :school, :created_by, :rows, :bus_prices, :fare_tiers, :scenarios ].freeze
      STALE_STUDY_FIELDS = %w[school_mode school_id prospect_lat prospect_lng pickup walk_m].freeze

      def index
        authorize Stop, :feasibility?
        list = FeasibilityStudy.includes(*INCLUDES).order(updated_at: :desc)
        render json: { data: list.map { summary(it) } }
      end

      def show
        authorize Stop, :feasibility?
        render json: { data: detail(find) }
      end

      # POST /feasibility_studies { study: { name, school_mode, school_id, prospect_name, prospect_postal, pickup, walk_m } }
      def create
        authorize Stop, :update?
        study = FeasibilityStudy.new(created_by: current_user)
        save(study)
        Feasibility::DEFAULT_PRICES.each { |type, p| study.bus_prices.create!(bus_type: type, **p) } unless params.key?(:bus_prices)
        study.scenarios.create!(position: 1, name: "Scenario 1", sizes: SchoolBus::BUS_TYPES.keys) if study.scenarios.empty?
        render json: { data: detail(find(study.id)) }, status: :created
      end

      # PATCH /feasibility_studies/:id { study: {…}, bus_prices: [{ bus_type, monthly, attendant }], fare_tiers: [{ max_km, fare, one_way_fare }] }
      def update
        authorize Stop, :update?
        save(find)
        render json: { data: detail(find) }
      end

      def destroy
        authorize Stop, :update?
        find.destroy!
        head :no_content
      end

      # POST /feasibility_studies/:id/rows { text } — "460101, 3, AM, P4" per line; DELETE /feasibility_studies/:id/rows clears them.
      def rows
        authorize Stop, :update?
        study = find
        if request.delete?
          study.rows.delete_all
        else
          list, bad = Feasibility.parse(params.require(:text))
          raise ApplicationService::Error, "No postal codes found. Put one postal code on each line" if list.empty?

          list.each do |r|
            row = study.rows.find_or_initialize_by(postal: r[:postal], session: r[:session], level: r[:level])
            row.riders = row.riders.to_i * (row.persisted? ? 1 : 0) + r[:riders]
            row.save!
          end
          skipped = bad
        end
        mark_stale(study)
        FeasibilityGeocodeJob.perform_later(study.id) unless request.delete?
        render json: { data: detail(find), meta: { skipped: skipped || 0 } }
      end

      # POST /feasibility_studies/:id/geocode — Check Again: look up the postal codes OneMap has not answered yet (202; poll
      # the study, each row is found / not_found / pending).
      def geocode
        authorize Stop, :update?
        study = find
        FeasibilityGeocodeJob.perform_later(study.id)
        render json: { data: detail(study) }, status: :accepted
      end

      # DELETE /feasibility_studies/:id/rows/:row_id — remove one line of students.
      def destroy_row
        authorize Stop, :update?
        study = find
        study.rows.find(params[:row_id]).destroy!
        mark_stale(study)
        render json: { data: detail(find) }
      end

      # POST /feasibility_studies/:id/copy — Copy Study (results are not copied).
      def copy
        authorize Stop, :update?
        render json: { data: detail(find(Feasibility::Copy.call(find, user: current_user).id)) }, status: :created
      end

      # POST /feasibility_studies/:id/scenarios { from_id } — Add Scenario (or copy one)
      def add_scenario
        authorize Stop, :update?
        study = find
        from = params[:from_id].present? ? study.scenarios.find(params[:from_id]) : nil
        n = study.scenarios.maximum(:position).to_i + 1
        attrs = from ? from.slice(:sizes, :attendant, :hard_cap, :target_cap, :margin_pct, :extra_buses, :params) : { sizes: SchoolBus::BUS_TYPES.keys }
        study.scenarios.create!(attrs.merge(position: n, name: from ? "#{from.name} (copy)" : "Scenario #{n}"))
        render json: { data: detail(find) }, status: :created
      end

      # PATCH /feasibility_scenarios/:id { scenario: { name, sizes, attendant, hard_cap, target_cap, margin_pct, extra_buses, params } }
      def update_scenario
        authorize Stop, :update?
        sc = find_scenario
        p = params.require(:scenario).permit(:name, :attendant, :hard_cap, :target_cap, :margin_pct, sizes: [], extra_buses: {}, params: {})
        p[:extra_buses] = params[:scenario][:extra_buses].permit!.to_h if params[:scenario][:extra_buses]
        p[:params] = params[:scenario][:params].permit!.to_h if params[:scenario][:params]
        sc.assign_attributes(p.to_h)
        sc.stale = true if sc.result.present? && sc.run_changed? # only the planning's inputs; a result never becomes fresh again by editing
        sc.save!
        render json: { data: detail(find(sc.feasibility_study_id)) }
      end

      def destroy_scenario
        authorize Stop, :update?
        sc = find_scenario
        raise ApplicationService::Error, "Keep at least one scenario" if sc.feasibility_study.scenarios.count == 1

        sc.destroy!
        head :no_content
      end

      # POST /feasibility_scenarios/:id/run — plans AM and PM in the background; poll the study.
      def run
        authorize Stop, :update?
        sc = find_scenario
        Feasibility::Run.check!(sc) # a 422 now, not a "failed" scenario after the 202
        sc.update!(status: "running", error: nil)
        FeasibilityRunJob.perform_later(sc.id)
        render json: { data: { id: sc.id, status: sc.status } }, status: :accepted
      end

      # POST /feasibility_scenarios/:id/use_suggested_fares
      def use_suggested
        authorize Stop, :update?
        sc = find_scenario
        study = sc.feasibility_study
        fares = Feasibility::Fares.call(study, sc, Feasibility::Cost.call(study, sc)) or raise ApplicationService::Error, "Run the scenario first"
        study.fare_tiers.delete_all
        fares[:tiers].each.with_index(1) do |t, i|
          study.fare_tiers.create!(position: i, max_km: t[:max_km], fare: t[:suggested], one_way_fare: t[:suggested_one_way])
        end
        render json: { data: detail(find(study.id)) }
      end

      # GET /feasibility_studies/fare_source?school_id= — the school's locked distance fares as monthly tiers.
      def fare_source
        authorize Stop, :feasibility?
        school = policy_scope(School).find(params.require(:school_id))
        year = school.academic_years.covering(Date.current).first
        table = year&.fare_table
        raise ApplicationService::Error, "#{school.name} has no locked distance fares this year" unless table&.locked? && !table.zones? && !table.per_bus?

        calc = FareTables::Calc.call(table, FareTables.periods(year, table))
        tiers = table.tiers.each_with_index.map do |t, i|
          k = calc[i][:std]
          two = k[:two] || k[:one]
          one = k[:am] ? [ k[:am][:annual], (k[:pm] || k[:am])[:annual] ].max : k.dig(:one, :annual)
          { max_km: i == table.tiers.size - 1 ? nil : t.max_km, fare: two && (two[:annual] / 12).round(2), one_way_fare: one && (one / 12).round(2) }
        end
        render json: { data: { year: year.key, tiers: } }
      end

      private

      def find(id = params[:id]) = FeasibilityStudy.includes(*INCLUDES).find(id)
      def find_scenario = FeasibilityScenario.joins(:feasibility_study).merge(FeasibilityStudy.all).find(params[:id])

      def save(study)
        p = params.fetch(:study, {}).permit(:name, :school_mode, :school_id, :prospect_name, :prospect_postal, :pickup, :walk_m)
        FeasibilityStudy.transaction do
          study.assign_attributes(p)
          study.school = policy_scope(School).find(p[:school_id]) if p[:school_id].present?
          study.validate! # every field's mistake at once, before OneMap is asked about the postal code
          locate(study) if study.school_mode == "prospect" && study.prospect_postal_changed?
          study.save!
          if params.key?(:bus_prices)
            study.bus_prices.delete_all
            params[:bus_prices].each { |b| study.bus_prices.create!(b.permit(:bus_type, :monthly, :attendant)) }
          end
          if params.key?(:fare_tiers)
            study.fare_tiers.delete_all
            params[:fare_tiers].each.with_index(1) { |t, i| study.fare_tiers.create!(t.permit(:max_km, :fare, :one_way_fare).merge(position: i)) }
          end
          mark_stale(study) if (study.saved_changes.keys & STALE_STUDY_FIELDS).any?
        end
      end

      # Results of every scenario that ran are out of date (the prototype's stale(Sx)): the students, the school's place,
      # how students are picked up or the walk changed.
      def mark_stale(study)
        study.scenarios.where.not(result: nil).update_all(stale: true) # rubocop:disable Rails/SkipsModelValidations
      end

      # Places a prospect school by its postal code (cleared when the postal code is).
      def locate(study)
        return study.assign_attributes(prospect_lat: nil, prospect_lng: nil, prospect_address: nil) if study.prospect_postal.blank?

        point = Geo::OneMap.lookup(study.prospect_postal) or raise ApplicationService::Error, "Postal code not found on OneMap"
        study.prospect_lat = point[:lat]
        study.prospect_lng = point[:lng]
        study.prospect_address = point[:address]
      rescue Geo::OneMap::Unavailable
        raise ApplicationService::Error, "OneMap cannot be reached. Try again in a moment"
      end

      def summary(s)
        best = s.scenarios.filter_map { Feasibility::Cost.call(s, it) }.min_by { it[:runs] }
        { id: s.id, name: s.name, school: s.place&.dig(:name), students: s.students, scenarios: s.scenarios.size, updated_at: s.updated_at,
          best: best&.slice(:buses, :runs, :total, :break_even) }
      end

      # A student line with what OneMap said about its postal code: found (address, lat, lng), not_found, or pending.
      def row_json(row, study)
        g = study.geocodes[row.postal]
        found = g&.found ? { address: g.address, lat: g.lat.to_f, lng: g.lng.to_f } : { address: nil, lat: nil, lng: nil }
        row.slice(:id, :postal, :riders, :session, :level).merge(status: g ? (g.found ? "found" : "not_found") : "pending", **found)
      end

      def geocode_counts(study)
        postals = study.rows.map(&:postal).uniq
        { postals: postals.size, pending: postals.count { !study.geocodes.key?(it) }, not_found: postals.count { study.geocodes[it]&.found == false } }
      end

      def detail(s)
        summary(s).merge(
          school_mode: s.school_mode, school_id: s.school_id, prospect_name: s.prospect_name, prospect_postal: s.prospect_postal, place: s.place,
          pickup: s.pickup, walk_m: s.walk_m, ran_at: s.ran_at, rows: s.rows.map { row_json(it, s) }, geocode: geocode_counts(s),
          bus_prices: s.bus_prices.map { it.slice(:bus_type, :monthly, :attendant) }, fare_tiers: s.fare_tiers.map { it.slice(:max_km, :fare, :one_way_fare) },
          scenarios: s.scenarios.map do |sc|
            cost = Feasibility::Cost.call(s, sc)
            sc.slice(:id, :name, :sizes, :attendant, :hard_cap, :target_cap, :margin_pct, :extra_buses, :params, :status, :stale, :error, :ran_at, :result)
              .merge(cost:, fares: Feasibility::Fares.call(s, sc, cost))
          end
        )
      end
    end
  end
end
