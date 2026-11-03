# Sample attendance on today's School Bus runs until the driver / attendant app records it (called by Telematics::Simulate:
# seed, `bin/rails live_map:simulate`; never in production, except staging with SAMPLE_DATA=1). For each run that has
# started: in the morning a child boards when the bus leaves their stop (QR pass, card, palm, or ticked by the attendant)
# and alights at the school gate once the run ends; in the afternoon everyone boards at the school and alights when the bus
# reaches their stop. A child with Bus Not Required has no row; every 17th child was not at the stop. Running it again
# writes the runs from the start.
module SchoolLive
  class Simulate < ApplicationService
    METHODS = %w[qr card qr palm card tick].freeze
    BLANK = %i[boarded_at board_method board_lat board_lng alighted_at alight_method alight_lat alight_lng].index_with(nil).freeze

    def initialize(now: Time.current)
      @now = now
    end

    def call
      raise Error, "Sample live data is not for production" if Rails.env.production? && ENV["SAMPLE_DATA"] != "1"

      School.find_each do |school|
        SchoolLive.runs(school, @now.to_date).each_value do |list|
          ctx = SchoolLive.context(school, @now.to_date, list)
          list.each { write(Run.new(it, school:, now: @now, **ctx)) }
        end
      end
    end

    private

    def write(run)
      occ = run.occ
      occ.passenger_marks.delete_all
      return unless run.started?

      attendant = run.route.attendant&.name || occ.decorate.driver_info&.dig(:name)
      rows = run.riders.filter_map do |k|
        next if k[:status] == "not_required"

        stop = run.stops[k[:stop][:index]]
        n = k[:rid].sum
        method = METHODS[n % METHODS.size]
        row = BLANK.merge(company_id: occ.company_id, occurrence_id: occ.id, occurrence_date: occ.date, passenger_key: k[:rid], source: "simulator",
                          marked_by: attendant, created_at: @now, updated_at: @now)
        if run.am?
          left = stop[:departed_at] || (run.done? ? stop[:planned_at] : nil)
          next unless left && left <= @now
          next row.merge(state: "not_boarded") if (n % 17).zero?

          at = left - 60 + ((n % 50) * 1)
          board = near(stop, n)
          school = run.school_point
          done = run.done? && run.school_at.nil? ? occ.ends_at : run.school_at
          row.merge(state: done ? "alighted" : "boarded", boarded_at: at, board_method: method, board_lat: board&.first, board_lng: board&.last,
                    alighted_at: done && done + (n % 3) * 20, alight_method: done && method, alight_lat: done && school[:lat], alight_lng: done && school[:lng])
        else
          left = occ.started_at || occ.starts_at
          next row.merge(state: "not_boarded") if (n % 17).zero?

          school = run.school_point
          off = stop[:arrived_at] || (run.done? ? stop[:planned_at] : nil)
          off = nil if off && off > @now
          row.merge(state: off ? "alighted" : "boarded", boarded_at: left - 120 + (n % 60), board_method: method,
                    board_lat: school[:lat], board_lng: school[:lng], alighted_at: off, alight_method: off && "tick",
                    alight_lat: off && stop[:lat], alight_lng: off && stop[:lng])
        end
      end
      OccurrencePassenger.insert_all!(rows) if rows.any?
    end

    # Where the pass was read: a few metres from the stop, now and then far enough to check.
    def near(stop, n)
      return nil unless stop[:lat]

      far = (n % 23).zero? ? 0.0006 : 0.0001
      [ stop[:lat] + (((n % 7) - 3) * far / 3), stop[:lng] + (((n % 5) - 2) * far / 2) ]
    end
  end
end
