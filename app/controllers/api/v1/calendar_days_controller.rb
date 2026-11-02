# Days on a calendar (also the Scheduler's Change a Day).
module Api
  module V1
    class CalendarDaysController < BaseController
      before_action :set_calendar

      def create
        day = authorize @calendar.days.new(day_params)
        day.save!
        render_data day, CalendarDayBlueprint, status: :created
      end

      def update
        day = authorize @calendar.days.find(params[:id])
        day.update!(day_params)
        render_data day, CalendarDayBlueprint
      end

      def destroy
        authorize(@calendar.days.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_calendar
        @calendar = Calendar.kept.find(params[:calendar_id])
      end

      def day_params
        params.expect(calendar_day: %i[kind starts_on ends_on label usual_time new_time shift_minutes in_place_of notify_drivers])
      end
    end
  end
end
