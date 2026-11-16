# Stop Bus Service: the last day a child needs the bus and why, one request (kind stop) per child. The notice comes from
# the school's Payment & Refund Policy in use (withdrawal notice, default 1 month): an earlier last day may be asked for,
# but fees run to the earliest last day the notice allows (the company confirms it: Stopping, then Stopped).
module ConvoyApp
  module Parents
    class StopService < RiderRequest
      WHY = { "leave" => "Leaving the School", "move" => "Moving House", "noneed" => "No Longer Needed", "other" => "Other Reason" }.freeze

      # { n:, unit:, earliest_on: } for a school today (call inside its company).
      def self.notice(school, today = Date.current)
        policy = SchoolPolicyVersion.current_for(school.policy_versions, today)
        n = policy&.withdrawal_notice.to_i.positive? ? policy.withdrawal_notice : 1
        unit = policy&.withdrawal_unit.presence || "months"
        earliest = case unit
        when "days" then today + n
        when "weeks" then today + (n * 7)
        else today >> n
        end
        { n:, unit:, earliest_on: Parents.next_weekday(earliest) }
      end

      def call
        kids = picked
        last = Date.parse(@params[:last_on].to_s)
        why = WHY.key?(@params[:why].to_s) ? @params[:why].to_s : "leave"
        note = @params[:why_note].to_s.strip
        raise Error, "Say why the bus is no longer needed" if why == "other" && note.empty?

        now = Time.current
        ApplicationRecord.transaction { kids.map { create(it, last, why, note, now) } }
      rescue Date::Error
        raise Error, "Pick a last day from tomorrow"
      end

      private

      def create(kid, last, why, note, now)
          Parents.within(kid.company) do
            today = Date.current
            raise Error, "Pick a last day from tomorrow" if last <= today
            if BusRequest.where(school_rider_id: kid.rider.id, kind: "stop").where(status: %w[Requested Stopping]).exists?
              raise Error, "#{kid.dependant.first_name} already has a request to stop"
            end

            n = self.class.notice(kid.school, today)
            year = year_on(kid.school, last)
            req = kid.school.bus_requests.create!(
              base(kid, year, now).merge(kind: "stop", am: kid.rider.am, pm: kid.rider.pm, last_on: last, stop_why: why, stop_why_note: why == "other" ? note : nil,
                                         notice_n: n[:n], notice_unit: n[:unit], earliest_on: n[:earliest_on], early: last < n[:earliest_on],
                                         current_fare: fare(kid, year, kid.service, kid.cca?, today))
            )
            log(req, "Request to stop", now)
            req
          end
      end
    end
  end
end
