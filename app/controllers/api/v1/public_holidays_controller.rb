# Public holidays (Calendars > Public Holidays): list by year, add, edit, remove, Add MOM [year] Dates.
module Api
  module V1
    class PublicHolidaysController < BaseController
      def index
        authorize PublicHoliday
        scope = policy_scope(PublicHoliday).order(:date)
        scope = scope.in_year(params[:year].to_i) if params[:year].present?
        render_list scope, PublicHolidayBlueprint
      end

      def create
        holiday = authorize PublicHoliday.new(holiday_params)
        holiday.save!
        render_data holiday, PublicHolidayBlueprint, status: :created
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
