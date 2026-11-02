# Client Invoices > Create Draft (a billing entity's runs of a month) and Invoice Now (one trip, even before it runs).
# One line per trip (its runs, period, quantity, unit price when every run costs the same) and one line per trip for
# late cancellations. Bill-to, terms and PO come from the client (or the site billed as its own entity); GST from Finance Settings.
module ClientInvoices
  class Draft < ApplicationService
    def initialize(client:, user:, site: nil, month: nil, trip: nil)
      @client = client
      @site = site
      @month = month&.beginning_of_month
      @trip = trip
      @user = user
    end

    def call
      entity = Billable.call(month: @month, trip: @trip, client_id: @client.id).find { |e| e.key == [ @client.id, @site&.id ] }
      raise Error, "Nothing to invoice for #{@site&.name || @client.name}#{@month ? " in #{@month.strftime('%B %Y')}" : ''}" if entity.nil? || (entity.bill + entity.late).empty?

      settings = FinanceSetting.current
      ClientInvoice.transaction do
        runs = entity.bill + entity.late
        invoice = ClientInvoice.create!(company_id: @client.company_id, client: @client, client_site: @site, trip: @trip, created_by: @user,
                                        **bill_to, terms_days: @client.terms_days, po: @client.default_po,
                                        period_from: @month || runs.map(&:date).min, period_to: @month&.end_of_month || runs.map(&:date).max,
                                        gst_on: settings.gst_on, gst_rate: settings.gst_rate, gst_mode: settings.gst_mode)
        add_lines(invoice, entity)
        invoice.recalculate!
        invoice
      end
    end

    private

    def bill_to
      contacts = (@site || @client).billing_contacts.to_a
      attention = contacts.find(&:attention)&.name
      if @site
        { bill_to_name: @site.billing_name, bill_to_uen: @site.billing_uen, bill_to_address: @site.billing_address, attention: }
      else
        { bill_to_name: @client.name, bill_to_uen: @client.uen, bill_to_address: @client.billing_address, attention: attention || @client.contact_name }
      end
    end

    def add_lines(invoice, entity)
      position = 0
      trips = (entity.bill + entity.late).map(&:trip).compact.uniq.sort_by { |t| [ t.starts_on, t.id ] }
      trips.each do |trip|
        [ [ "trip", entity.bill ], [ "late_cancel", entity.late ] ].each do |source, list|
          runs = list.select { |o| o.trip_id == trip.id }
          next if runs.empty?

          add_line(invoice, trip, source, runs, position += 1)
        end
      end
    end

    def add_line(invoice, trip, source, runs, position)
      prices = runs.map { |o| o.price.to_d }.uniq
      dates = runs.map(&:date)
      period = dates.min == dates.max ? dates.min.strftime("%-d %b %Y") : "#{dates.min.strftime('%-d %b')} to #{dates.max.strftime('%-d %b %Y')}"
      t = trip.decorate
      line = invoice.lines.create!(position:, source:, trip:, ref: t.trip_id, period_text: period, quantity: runs.size,
                                   unit_price: prices.one? ? prices.first : nil, amount: runs.sum { |o| o.price.to_d },
                                   description: source == "trip" ? "#{trip.title} (#{trip.kind_name})" : "Late cancellation: #{trip.title}",
                                   details: [ t.route_text.presence, t.vehicles_required_text.presence ].compact.join(" | "))
      runs.each do |o|
        line.runs.create!(occurrence_id: o.id, occurrence_date: o.date, start_time: o.start_time, trip_label: o.trip_label, amount: o.price)
      end
    end
  end
end
