# Public holidays (Calendars > Public Holidays): list by year, add, edit, remove, Add MOM [year] Dates.
module Api
  module V1
    class PublicHolidaysController < BaseController
      # GET /public_holidays?year=2026 — with year: meta for the card title and the Add MOM [year] Dates button.
      def index
        authorize PublicHoliday
        scope = policy_scope(PublicHoliday).order(:date)
        return render_list(scope, PublicHolidayBlueprint) if params[:year].blank?

        year = params[:year].to_i
        holidays = scope.in_year(year).to_a
        missing = PublicHoliday.preset(current_company.country, year).count { |h| holidays.none? { |x| x.date.iso8601 == h["date"] } }
        render_list holidays, PublicHolidayBlueprint,
                    meta: { year:, count: holidays.size, weekdays: holidays.count { |h| !h.date.on_weekend? },
                            preset_available: PublicHoliday.preset(current_company.country, year).any?, preset_missing: missing }
      end

      # POST /public_holidays — a holiday on a Sunday also adds the Monday after as the observed holiday (meta.observed).
      def create
        holiday = authorize PublicHoliday.new(holiday_params)
        observed = PublicHoliday.transaction do
          holiday.save!
          holiday.add_observed_monday!
        end
        render json: { data: PublicHolidayBlueprint.render_as_hash(holiday),
                       meta: { observed: observed && PublicHolidayBlueprint.render_as_hash(observed) } }, status: :created
      end

      def update
        holiday = authorize PublicHoliday.find(params[:id])
        holiday.update!(holiday_params)
        render_data holiday, PublicHolidayBlueprint
      end

      def destroy
        authorize(PublicHoliday.find(params[:id])).destroy!
        head :no_content
      end

      # POST /public_holidays/import { year } — adds the gazetted dates not on the list yet.
      def import
        authorize PublicHoliday
        added = PublicHoliday.import_preset!(current_company.country, params.require(:year).to_i)
        render_list added, PublicHolidayBlueprint, meta: { added: added.size }
      end

      private

      def holiday_params = params.expect(public_holiday: %i[date name observed])
    end
  end
end
