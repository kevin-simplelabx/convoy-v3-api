# Mark a student on a run: boarded, alighted, absent, or clear.
module SchoolRuns
  class MarkAttendance < ApplicationService
    MARKS = %w[boarded alighted absent clear].freeze

    def initialize(occurrence:, student_key:, mark:, user:)
      @occ = occurrence
      @key = student_key
      @mark = mark.to_s
      @user = user
    end

    def call
      raise Error, "Mark boarded, alighted, absent or clear" unless MARKS.include?(@mark)

      student = Passengers.call(@occ)[:stops].flat_map { |s| s[:students] }.find { |s| s[:key] == @key }
      raise Error, "This student is not on the run" if student.nil?

      row = StudentAttendance.find_or_initialize_by(trip_id: @occ.trip_id, run_date: @occ.date, trip_run_id: @occ.trip_run_id,
                                                     slot_no: @occ.slot_no, student_key: @key)
      now = Time.current
      row.assign_attributes(student_name: student[:name], recorded_by: @user)
      case @mark
      when "boarded" then row.assign_attributes(boarded_at: row.boarded_at || now, absent: false)
      when "alighted" then row.assign_attributes(boarded_at: row.boarded_at || now, alighted_at: now, absent: false)
      when "absent" then row.assign_attributes(absent: true, boarded_at: nil, alighted_at: nil)
      else return row.persisted? ? row.destroy! : row
      end
      row.save!
      row
    end
  end
end
