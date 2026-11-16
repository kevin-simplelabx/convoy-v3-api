# Change Service: the sessions a child rides (and the CCA bus) from one of the next 8 Mondays, one request (kind svc) per
# child whose service changes, with the fare now and after (Family's home, this year's Bus Fares). Adding a session or the
# CCA bus may need a route change (adds, mid-year deadlines); dropping one is confirmed quickly.
module ConvoyApp
  module Parents
    class ChangeService < RiderRequest
      def call
        kids = picked
        from = Date.parse(@params[:from].to_s)
        now = Time.current
        rows = kids.filter_map do |kid|
          Parents.within(kid.company) do
            raise Error, "Pick the date from the list" unless Parents.mondays(Date.current).include?(from)

            p = per(kid)
            service = SERVICES.key?(p[:service].to_s) ? p[:service].to_s : kid.service
            cca = ActiveModel::Type::Boolean.new.cast(p[:cca]) || false
            next if service == kid.service && cca == kid.cca?

            { kid:, service:, cca: }
          end
        end
        raise Error, "Pick a different service for at least one child" if rows.empty?

        ApplicationRecord.transaction { rows.map { create(it, from, now) } }
      rescue Date::Error
        raise Error, "Pick the date from the list"
      end

      private

      def create(r, from, now)
          kid = r[:kid]
          Parents.within(kid.company) do
            year = year_on(kid.school, from)
            win = Parents.window(kid.school, Date.current)
            adds = (kid.service != "both" && r[:service] != kid.service) || (r[:cca] && !kid.cca?)
            req = kid.school.bus_requests.create!(
              base(kid, year, now).merge(kind: "svc", old_am: kid.rider.am, old_pm: kid.rider.pm, old_cca: kid.cca?, am: r[:service] != "pm",
                                         pm: r[:service] != "am", cca: r[:cca], effective_on: from, start_on: from, adds:, mid: adds && Parents.mid?(win, Date.current),
                                         current_fare: fare(kid, year, kid.service, kid.cca?, from), estimate: fare(kid, year, r[:service], r[:cca], from))
            )
            log(req, "Change of service", now)
            req
          end
      end
    end
  end
end
