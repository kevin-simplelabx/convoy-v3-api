# Where the Household meets School Bus: each child's bus badge and what stops Delete Family. Read from every company the
# Family deals with (its requests and the families accepting copied it into), each inside its own company.
# A child rides (Active) while a rider linked to them is on the list today or later and no first invoice is still owed;
# otherwise the badge is their latest bus service application's (ConvoyApp::Parents::Present.badge).
module ConvoyApp
  module Households
    module BusService
      NONE = { code: "no_bus", label: "No Bus Yet", tone: "neutral" }.freeze
      ACTIVE = { code: "active", label: "Active", tone: "success" }.freeze

      module_function

      # The badge on one child's row.
      def status(dependant) = statuses(dependant.household)[dependant.id] || NONE

      # { dependant_id => badge } for the Family's children (no entry = No Bus Yet).
      def statuses(household)
        facts(household).transform_values do |f|
          next ACTIVE if f[:riding]
          next NONE unless (req = f[:request])

          b = ConvoyApp::Parents::Present.badge(req, f[:now])
          { code: b[:label].parameterize(separator: "_"), label: b[:label], tone: b[:tone], request_id: req.id }
        end
      end

      # Why Delete Family is refused: [{ code:, label: }] — a child riding (active_service), an application accepted and
      # waiting for its first invoice (open_request), an unpaid bill of the Family (registration fee, first invoice, period
      # bill: Fees.outstanding). Empty = may delete.
      def delete_blockers(household)
        names = household.dependants.index_by(&:id)
        facts(household).flat_map do |id, f|
          first = names[id]&.first_name || "A child"
          out = []
          out << { code: "active_service", label: "#{first} rides the school bus" } if f[:riding]
          out << { code: "open_request", label: "#{first} has an accepted bus request" } if f[:request]&.live_status(f[:now]) == "Accepted"
          f[:unpaid].each { out << { code: "unpaid_bill", label: "#{it} is not paid" } }
          out
        end.concat(ConvoyApp::Fees.outstanding(household).map { { code: "unpaid_bill", label: "#{it[:row].bill.number} is not paid" } }).uniq
      end

      # Per child: { riding:, request: (latest application, not withdrawn), unpaid: [bill numbers], now: }.
      def facts(household)
        ids = household.dependants.map(&:id)
        return {} if ids.empty?

        out = Hash.new { |h, k| h[k] = { riding: false, request: nil, unpaid: [], now: Time.current } }
        ConvoyApp::Parents.companies(household).each do |company|
          ConvoyApp::Parents.within(company) { collect(household, ids, out) }
        end
        out.to_h
      end

      def collect(household, ids, out)
        now = Time.current
        today = Date.current
        reqs = BusRequest.where(dependant_id: ids, kind: "new").where.not(status: "Withdrawn").includes(:company, :registration_bill, first_bill: :payments)
                         .order(:submitted_at, :id).to_a
        reqs.each do |r|
          f = out[r.dependant_id]
          f[:now] = now
          f[:request] = r if f[:request].nil? || f[:request].submitted_at <= r.submitted_at
          f[:unpaid] |= [ r.registration_bill.number ] if r.registration_bill && !r.fee_paid
          f[:unpaid] |= [ r.first_bill.number ] if r.first_bill&.issued? && !r.first_bill.paid? && r.live_status(now) == "Accepted"
        end
        frs = FamilyRider.where(dependant_id: ids, family_id: Family.where(household_id: household.id).select(:id)).to_a
        listed = SchoolRider.where(school_id: frs.map(&:school_id).uniq, rid: frs.map(&:rid).uniq).where(ends_on: [ nil, today.. ])
                            .pluck(:school_id, :rid).to_set
        frs.each do |fr|
          next unless listed.include?([ fr.school_id, fr.rid ])

          f = out[fr.dependant_id]
          f[:riding] = true unless ConvoyApp::Parents.pending_offer?(f[:request], now)
        end
      end
    end
  end
end
