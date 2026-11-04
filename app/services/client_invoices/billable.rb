# Client Invoices: the runs that can be billed, by billing entity [client_id, own-billing site_id or nil].
# Month mode (Ready to Invoice): runs of the month up to today. Trip mode (Invoice Now): every run of one trip, also future.
# A run is billed when it has a client price, no issue raised (month mode) and is not on an invoice that is not void.
# A run the client cancelled inside their cut-off (late_cancel_hours, 24 by default) is billed in full as a late
# cancellation; other cancelled runs are not billed. Runs that can't be billed are listed with why.
module ClientInvoices
  class Billable < ApplicationService
    Entity = Struct.new(:client, :site, :bill, :late, :blocked, keyword_init: true) do
      def key = [ client.id, site&.id ]
      def amount = (bill + late).sum(0.to_d, &:price)
      def name = site ? "#{site.billing_name || client.name} | #{site.name}" : client.name
    end

    def initialize(month: nil, trip: nil, client_id: nil, today: Date.current)
      @month = month&.beginning_of_month
      @trip = trip
      @client_id = client_id
      @today = today
    end

    def call
      runs = scope.to_a
      billed = ClientInvoiceLineRun.where(active: true, occurrence_id: runs.map(&:id)).pluck(:occurrence_id, :occurrence_date).to_set
      entities = {}
      runs.each do |occ|
        next if billed.include?([ occ.id, occ.date ])

        site = occ.trip&.client_site
        site = nil unless site&.own_billing?
        e = entities[[ occ.client_id, site&.id ]] ||= Entity.new(client: occ.client, site:, bill: [], late: [], blocked: [])
        classify(e, occ)
      end
      entities.values.reject { |e| e.bill.empty? && e.late.empty? && e.blocked.empty? }
    end

    private

    def scope
      s = TripOccurrence.visible.where.not(client_id: nil).includes(:client, trip: :client_site).chronological
      s = s.where(client_id: @client_id) if @client_id
      return s.where(trip_id: @trip.id) if @trip

      s.between(@month, [ @month.end_of_month, @today ].min)
    end

    def classify(e, occ)
      if occ.cancelled?
        e.late << occ if late_cancel?(occ)
      elsif occ.price.to_d <= 0
        e.blocked << [ occ, "No client price on the trip" ]
      elsif occ.issue_raised_at && !@trip
        e.blocked << [ occ, "An issue is raised on this run" ]
      else
        e.bill << occ
      end
    end

    # Hours before the start the run was cancelled, rounded ("cancelled 3 h before").
    def self.hours_before(occ) = occ.cancelled_at && [ ((occ.starts_at - occ.cancelled_at) / 3600.0).round, 0 ].max

    def late_cancel?(occ)
      occ.cancelled_by_client? && occ.cancelled_at && occ.price.to_d.positive? &&
        (occ.starts_at - occ.cancelled_at) < occ.client.late_cancel_hours.hours
    end
  end
end
