# School Bus › Year Setup › Terms & Semesters: a school's academic years, New Academic Year, a year's calendar (terms,
# CCA periods, holidays, special days), Save Calendar (locks it), Unlock to Edit and Delete Year.
module Api
  module V1
    class AcademicYearsController < BaseController
      INCLUDES = [ :terms, :holidays, :special_days, { setup_locks: :locked_by } ].freeze

      # GET /schools/:school_id/academic_years
      def index
        school = authorize find_school, :show?
        render_list school.academic_years.includes(setup_locks: :locked_by), AcademicYearBlueprint
      end

      # POST /schools/:school_id/academic_years { start_year, start_month, copy_from_id }
      def create
        school = authorize find_school, :setup?
        copy = params[:copy_from_id].presence && school.academic_years.find(params[:copy_from_id])
        year = AcademicYears::Create.call(school:, start_year: params[:start_year], start_month: params[:start_month], copy_from: copy)
        render_data year, AcademicYearBlueprint, view: :detail, status: :created
      end

      def show
        year = find_year
        authorize year.school, :show?
        render_data year, AcademicYearBlueprint, view: :detail
      end

      # PUT /academic_years/:id/calendar { operating_days: [1..7], structure, period_count, cca_same_as_terms,
      #   terms: [{ starts_on, ends_on, cca_starts_on, cca_ends_on }] }
      def update_calendar
        year = find_year
        authorize year.school, :setup?
        AcademicYears::SaveCalendar.call(year, calendar_params, user: current_user)
        render_data find_year, AcademicYearBlueprint, view: :detail
      end

      # POST /academic_years/:id/unlock { section: calendar | sessions }
      def unlock
        year = find_year
        section = params.require(:section)
        raise ApplicationService::Error, "Unknown step" unless SetupLock::YEAR_SECTIONS.include?(section)

        authorize year.school, section == "fares" ? :money_setup? : :setup?

        SchoolSetup.unlock!(school: year.school, year:, section:)
        render_data find_year, AcademicYearBlueprint, view: :detail
      end

      # PUT /academic_years/:id/holidays { holidays: [{ name, starts_on, ends_on, public_holiday_id }],
      #   special_days: [{ date, kind, time, description }] } — the whole list (Save Changes).
      def update_holidays
        year = find_year
        authorize year.school, :setup?
        list = params.permit(holidays: %i[name starts_on ends_on public_holiday_id], special_days: %i[date kind time description]).to_h.deep_symbolize_keys
        AcademicYears::SaveHolidays.call(year, holidays: list[:holidays], special_days: list[:special_days])
        render_data find_year, AcademicYearBlueprint, view: :detail
      end

      # GET /academic_years/:id/public_holidays — Import Public Holidays: the company's public holidays inside the year
      # that are not on its list yet (the screen adds them to the draft).
      def public_holidays
        year = find_year
        authorize year.school, :show?
        taken = year.holidays.map { |h| [ h.public_holiday_id, h.starts_on ] }
        list = PublicHoliday.between(year.starts_on, year.ends_on).order(:date)
                            .reject { |h| taken.any? { |id, d| id == h.id || d == h.date } }
        render json: { data: list.map { |h| { public_holiday_id: h.id, name: h.name, starts_on: h.date, ends_on: h.date } } }
      end

      # GET /academic_years/:id/setup — the Year Setup steps (done = locked) for the strip and the Summary.
      def setup
        year = find_year
        authorize year.school, :show?
        render json: { data: SchoolSetup::Steps.new(year).call }
      end

      def destroy
        year = find_year
        authorize year.school, :delete_year?
        AcademicYears::Destroy.call(year)
        head :no_content
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])
      def find_year = AcademicYear.where(school: policy_scope(School)).includes(:school, *INCLUDES).find(params[:id])

      def calendar_params
        params.permit(:structure, :period_count, :cca_same_as_terms, operating_days: [], terms: %i[starts_on ends_on cca_starts_on cca_ends_on])
              .to_h.deep_symbolize_keys
      end
    end
  end
end
