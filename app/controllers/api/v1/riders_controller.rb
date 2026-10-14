module Api
  module V1
    class RidersController < BaseController
      before_action :require_company!
      before_action :load_school
      before_action -> { require_permission!("schools") }, only: [ :create, :update_labels ]

      # GET /api/v1/schools/:school_id/riders?date=YYYY-MM-DD
      def index
        date = params[:date].presence&.slice(0, 10) || Date.today.iso8601

        dataset = @school.datasets.active_on(date).first
        csv_riders = dataset ? dataset.rows.select { |r| rider_active_on?(r, date) }.map { |r| r.merge("source" => "csv") } : []

        manual = @school.riders.select { |r| r.active_on?(Date.parse(date)) }.map do |r|
          rider_to_hash(r).merge("source" => "manual")
        end

        render json: {
          dataset: dataset ? DatasetBlueprint.render_as_hash(dataset, view: :summary) : nil,
          riders:  csv_riders + manual
        }
      end

      # POST /api/v1/schools/:school_id/riders
      def create
        p = params.permit(:rid, :name, :gender, :grade, :address, :postal, :lat, :lng,
                          :am, :pm, :cca, :start_date, :end_date, :parent_name, :parent_contact, :remarks)
        return render_error("Name is required") if p[:name].blank?

        rider = @school.riders.create!(
          rid:            p[:rid].presence || SecureRandom.hex(5),
          name:           p[:name].strip,
          gender:         p[:gender].to_s,
          grade:          p[:grade].to_s,
          address:        p[:address].to_s,
          postal:         p[:postal].to_s,
          lat:            p[:lat],
          lng:            p[:lng],
          am:             p[:am].nil? ? true : ActiveModel::Type::Boolean.new.cast(p[:am]),
          pm:             p[:pm].nil? ? true : ActiveModel::Type::Boolean.new.cast(p[:pm]),
          cca:            p[:cca].to_s,
          start_date:     p[:start_date].presence,
          end_date:       p[:end_date].presence,
          parent_name:    p[:parent_name].to_s,
          parent_contact: p[:parent_contact].to_s,
          remarks:        p[:remarks].to_s
        )
        render json: rider_to_hash(rider).merge("source" => "manual"), status: :created
      end

      # GET /api/v1/schools/:school_id/rider-events
      def events
        datasets = @school.datasets.order(:effective_from)
        manual   = @school.riders.order(:start_date)
        render json: RiderEventsService.new(datasets, manual).call
      end

      # GET /api/v1/schools/:school_id/labels
      def labels
        render json: @school.effective_labels
      end

      # PUT /api/v1/schools/:school_id/labels
      def update_labels
        @school.update!(labels: params.except(:school_id, :controller, :action).to_unsafe_h)
        render json: @school.effective_labels
      end

      private

      def load_school
        @school = current_company.schools.find_by(id: params[:school_id])
        render_error("School not found", :not_found) unless @school
      end

      def rider_active_on?(row, date)
        (row["start"].blank? || row["start"] <= date) &&
          (row["end"].blank? || row["end"] >= date)
      end

      def rider_to_hash(r)
        {
          "id" => r.id, "rid" => r.rid, "name" => r.name, "gender" => r.gender,
          "grade" => r.grade, "address" => r.address, "postal" => r.postal,
          "lat" => r.lat, "lng" => r.lng, "am" => r.am, "pm" => r.pm,
          "cca" => r.cca, "start" => r.start_date&.iso8601, "end" => r.end_date&.iso8601,
          "parentName" => r.parent_name, "parentContact" => r.parent_contact,
          "remarks" => r.remarks, "schoolId" => r.school_id
        }
      end
    end
  end
end
