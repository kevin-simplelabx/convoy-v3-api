# School Bus › school › Riders: the riders on a date (the list in use and the ones added by hand) with the All / AM / PM
# / CCA / Unlocated counts and search, Add Rider, and the CSV export.
module Api
  module V1
    class SchoolRidersController < BaseController
      EXPORT_COLUMNS = %w[student_id student_name gender grade_class address postal_code am pm cca_days start_date end_date
                          parent_name parent_contact remarks].freeze

      # GET /schools/:school_id/riders?date=&filter=all|am|pm|cca|unlocated&q=&page=&limit=
      def index
        school = authorize find_school, :show?
        date = day
        all = SchoolRider.of_school_on(school, date)
        all = all.search(params[:q]) if params[:q].present?
        counts = SchoolRider::FILTERS.index_with { all.filtered(it).count }
        list = school.rider_datasets.in_use_on(date)
        render_page all.filtered(params[:filter]).order(:name, :id), SchoolRiderBlueprint,
                    meta: { date:, counts:, dataset: list && RiderDatasetBlueprint.render_as_hash(list.decorate, date:, in_use: list) }
      end

      # POST /schools/:school_id/riders { rider: { first_name, last_name, name_order, rid, gender, grade, address, postal, am, pm,
      #   cca_days, starts_on, ends_on, parent_name, parent_contact, remarks }, family_id }
      def create
        school = authorize find_school, :manage_riders?
        rider = SchoolRiders::Add.call(school:, params: rider_params, user: current_user)
        # From a family (Add New Rider): the rider joins it.
        Families.link(Family.where(school: policy_scope(School)).find(params[:family_id]), school, [ rider.rid ]) if params[:family_id].present?
        render_data rider, SchoolRiderBlueprint, status: :created
      end

      # PATCH /schools/:school_id/riders/:rid { rider: { ... } } — a rider added by hand; the same fields as Add Rider, all optional.
      def update
        school = authorize find_school, :manage_riders?
        rider = school.riders.manual.find_by!(rid: params[:rid])
        render_data SchoolRiders::Update.call(rider:, params: rider_params), SchoolRiderBlueprint
      end

      # DELETE /schools/:school_id/riders/:rid — a rider added by hand that nothing uses (answers 204).
      def destroy
        school = authorize find_school, :manage_riders?
        SchoolRiders::Remove.call(rider: school.riders.manual.find_by!(rid: params[:rid]))
        head :no_content
      end

      # GET /schools/:school_id/riders/export?date= — CSV in the upload template's columns.
      def export
        school = authorize find_school, :show?
        date = day
        csv = CSV.generate do |out|
          out << EXPORT_COLUMNS
          SchoolRider.of_school_on(school, date).order(:name).each do |r|
            out << [ r.rid, r.name, r.gender, r.grade, r.address, r.postal, r.am ? "Y" : "N", r.pm ? "Y" : "N", r.cca_text, r.starts_on, r.ends_on,
                     r.parent_name, r.parent_contact, r.remarks ]
          end
        end
        send_data csv, filename: "#{school.short} riders #{date}.csv", type: "text/csv"
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def rider_params
        params.expect(rider: [ :first_name, :last_name, :name_order, :rid, :gender, :grade, :address, :postal, :am, :pm, :starts_on, :ends_on,
                               :parent_name, :parent_contact, :remarks, :cca_days, { cca_days: [] } ])
      end

      def day
        params[:date].present? ? Date.iso8601(params[:date]) : Date.current
      rescue Date::Error
        raise ApplicationService::Error, "Date must look like 2026-11-02"
      end
    end
  end
end
