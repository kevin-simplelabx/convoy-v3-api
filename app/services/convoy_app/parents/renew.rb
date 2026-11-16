# Renew for <yr>: a new request (renew, tag Renewing) per child for the next year while the school takes renewals (the
# early window), with the level in that year (required), the service and the CCA bus; the fare is the next year's Bus Fares
# when saved ("The <yr> fare comes with the confirmation" otherwise). Accepted renewals get a first invoice; paying it
# makes them Active.
module ConvoyApp
  module Parents
    class Renew < RiderRequest
      def call
        kids = picked
        now = Time.current
        rows = kids.map do |kid|
          Parents.within(kid.company) do
            today = Date.current
            win = Parents.window(kid.school, today, renew: true)
            unless win&.state == "open" && win.year.starts_on > today
              raise Error, "#{kid.school.name} is not taking renewals now"
            end
            if BusRequest.where(school_rider_id: kid.rider.id, academic_year: win.year, renew: true).where.not(status: %w[Withdrawn Declined]).exists?
              raise Error, "#{kid.dependant.first_name} already has a renewal for #{win.year.key}"
            end

            p = per(kid)
            level = p[:level].to_s.squish
            raise Error, "Choose the level for #{win.year.key}" if level.empty?

            service = SERVICES.key?(p[:service].to_s) ? p[:service].to_s : kid.service
            cca = ActiveModel::Type::Boolean.new.cast(p[:cca]) || false
            { kid:, win:, level:, service:, cca: }
          end
        end
        ApplicationRecord.transaction { rows.map { create(it, now) } }
      end

      private

      def create(r, now)
          Parents.within(r[:kid].company) do
            kid = r[:kid]
            win = r[:win]
            req = kid.school.bus_requests.create!(
              base(kid, win.year, now).merge(kind: "new", renew: true, tags: [ "Renewing" ], level: r[:level], am: r[:service] != "pm", pm: r[:service] != "am",
                                             cca: r[:cca], start_when: "first", start_on: win.starts_on, same: r[:service] == kid.service && !r[:cca],
                                             estimate: own_fares?(kid.school, win.year) ? fare(kid, win.year, r[:service], r[:cca], win.starts_on) : nil, terms_agreed_at: now,
                                             policy_version: SchoolPolicyVersion.current_for(kid.school.policy_versions, now.to_date)&.version)
            )
            log(req, "Renewal for #{win.year.key}", now)
            req
          end
      end
    end
  end
end
