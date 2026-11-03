# School Bus › Families & Riders: a school's families (search, unlinked riders), a family with its guardians and riders
# (service, where they ride now), add / rename / delete, guardians, link / unlink riders (with the riders it could
# take), and the CSV import / export.
module Api
  module V1
    class FamiliesController < BaseController
      # GET /schools/:school_id/families?q=&page=
      def index
        school = find_school
        authorize Family
        scope = Families.search(school.families.includes(:guardians, :family_riders), school, params[:q]).order(:name, :id)
        pagy, list = pagy(scope)
        names = SchoolRider.where(school:).pluck(:rid, :name).to_h
        on_list = SchoolRider.of_school_on(school, Date.current).pluck(:rid)
        unlinked = on_list.size - FamilyRider.where(school:, rid: on_list).count
        render json: { data: list.map { row(it, school, names) },
                       meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, unlinked_riders: unlinked } }
      end

      def show
        family = authorize find
        render json: { data: detail(family) }
      end

      # POST /schools/:school_id/families { family: { code, name, name_mode }, guardian: { first_name, last_name, relationship, phone, email } }
      def create
        school = find_school
        authorize Family
        family = Family.transaction do
          f = school.families.new(code: params.dig(:family, :code).presence || Family.next_code, name: params.dig(:family, :name).presence || "New Family",
                                  name_mode: params.dig(:family, :name_mode) || "auto")
          f.save!
          f.guardians.create!(guardian_params) if params[:guardian].present?
          f.save!
          f
        end
        render json: { data: detail(find(family.id)) }, status: :created
      end

      # PATCH /families/:id { family: { code, name, name_mode } }
      def update
        family = authorize find
        family.update!(params.expect(family: %i[code name name_mode]))
        render json: { data: detail(find) }
      end

      def destroy
        authorize(find).destroy!
        head :no_content
      end

      # POST /families/:id/guardians { guardian: {…} } · PATCH / DELETE /families/:id/guardians/:guardian_id
      def guardian
        family = authorize find, :update?
        if request.post? then family.guardians.create!(guardian_params.merge(position: family.guardians.size))
        elsif request.delete? then family.guardians.find(params[:guardian_id]).destroy!
        else family.guardians.find(params[:guardian_id]).update!(guardian_params)
        end
        family.reload.save!
        render json: { data: detail(find) }
      rescue ActiveRecord::RecordInvalid => e
        raise ApplicationService::Error, e.record.errors.full_messages.to_sentence
      end

      # POST /families/:id/riders { school_id, rids: [] } — link (a rider leaves any other family at the school)
      def link
        family = authorize find, :update?
        Families.link(family, rider_school(family), Array(params.require(:rids)).map(&:to_s))
        render json: { data: detail(find) }
      end

      # DELETE /families/:id/riders/:rid?school_id=
      def unlink
        family = authorize find, :update?
        family.family_riders.where(school: rider_school(family), rid: params[:rid]).delete_all
        render json: { data: detail(find) }
      end

      # GET /families/:id/candidates?school_id=&q= — Link Existing Rider: parent matches, then same last name.
      def candidates
        family = authorize find, :show?
        render json: { data: Families.candidates(family, rider_school(family), q: params[:q]) }
      end

      # POST /schools/:school_id/families/import { file | text }
      def import
        school = find_school
        authorize Family, :create?
        text = params[:file].respond_to?(:read) ? params[:file].read : params.require(:text)
        render json: { data: Families::Import.call(school, text) }
      end

      # GET /schools/:school_id/families/export
      def export
        school = find_school
        authorize Family, :index?
        send_data Families.export(school), filename: "#{school.short} families.csv", type: "text/csv"
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])
      def find(id = params[:id]) = Family.where(school: policy_scope(School)).includes(:school, :guardians, :family_riders).find(id)
      def rider_school(family) = params[:school_id].present? ? policy_scope(School).find(params[:school_id]) : family.school

      def guardian_params = params.require(:guardian).permit(:first_name, :last_name, :name_order, :relationship, :phone, :email)

      def guardian_row(g) = g.slice(:id, :first_name, :last_name, :name_order, :relationship, :phone, :email, :app_joined_at, :app_joined_how).merge(name: g.name)

      def row(f, school, names)
        kids = f.family_riders.select { it.school_id == school.id }
        g = f.guardians.first
        { id: f.id, code: f.code, name: f.name, name_mode: f.name_mode, source: f.source, sample: f.sample, guardians: f.guardians.size,
          first_guardian: g && { name: g.name, relationship: g.relationship, phone: g.phone },
          children: kids.map { { rid: it.rid, name: names[it.rid] } } }
      end

      def detail(f)
        links = f.family_riders.to_a
        riders = SchoolRider.where(school_id: links.map(&:school_id).uniq, rid: links.map(&:rid)).index_by { [ it.school_id, it.rid ] }
        rides = rides_of(links)
        f.slice(:id, :code, :name, :name_mode, :source, :sample, :address, :postal, :registered_at, :school_id).merge(
          guardians: f.guardians.map { guardian_row(it) },
          riders: links.map do |l|
            r = riders[[ l.school_id, l.rid ]]
            { school_id: l.school_id, rid: l.rid, name: r&.name, grade: r&.grade, am: r&.am, pm: r&.pm, cca_days: r&.cca_days, starts_on: r&.starts_on,
              ends_on: r&.ends_on, on_list: r.present?, applied_at: l.applied_at, accepted_at: l.accepted_at, rides: rides[[ l.school_id, l.rid ]] || [] }
          end
        )
      end

      # Where each rider rides now: the route, stop and time in the current plans of their school.
      def rides_of(links)
        return {} if links.empty?

        today = Date.current
        rows = SchoolRouteRider.joins(stop: { route: :plan }).where(rid: links.map(&:rid), school_plans: { school_id: links.map(&:school_id).uniq, in_use: true })
                               .where("school_plans.effective_from <= :d AND (school_plans.effective_to IS NULL OR school_plans.effective_to >= :d)", d: today)
                               .pluck("school_plans.school_id", :rid, "school_plans.session", "school_routes.label", "school_route_stops.name", "school_route_stops.scheduled_time")
        rows.group_by { [ it[0], it[1] ] }.transform_values do |list|
          list.map { |_, _, se, label, stop, t| { session: se, route: label, stop:, time: Clock.hm(t) } }
        end
      end
    end
  end
end
