# User calendars (school or general) with their days. New school calendars start from the MOE preset,
# blank, or a copy of another calendar.
module Api
  module V1
    class CalendarsController < BaseController
      def index
        authorize Calendar
        render_list policy_scope(Calendar).kept.order(:name), CalendarBlueprint
      end

      def show
        render_data authorize(find_calendar), CalendarBlueprint, view: :with_days
      end

      # POST /calendars { calendar: {name, kind, observed_holidays}, start_from: moe | blank | <calendar id> }
      def create
        calendar = authorize Calendar.new(calendar_params)
        Calendar.transaction do
          calendar.save!
          start_from(calendar)
        end
        render_data calendar.reload, CalendarBlueprint, view: :with_days, status: :created
      end

      def update
        calendar = authorize find_calendar
        calendar.update!(calendar_params)
        render_data calendar, CalendarBlueprint, view: :with_days
      end

      def destroy
        calendar = find_calendar
        authorize calendar, :update?
        return render_error(:unprocessable_content, "This calendar is used by trips, so it can't be deleted") if calendar.in_use?

        calendar.discard!
        head :no_content
      end

      private

      def find_calendar = policy_scope(Calendar).kept.includes(:days).find(params[:id])

      def calendar_params = params.expect(calendar: %i[name kind observed_holidays morning_time afternoon_time])

      def start_from(calendar)
        case params[:start_from]
        when "moe" then calendar.apply_moe_preset! if calendar.school?
        when /\A\d+\z/
          source = policy_scope(Calendar).kept.find(params[:start_from])
          source.days.each { |d| calendar.days.create!(d.attributes.except("id", "calendar_id", "created_at", "updated_at")) }
        end
      end
    end
  end
end
