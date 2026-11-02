# Client Invoices: Record Payment, Credit Note and Email (recorded) on an issued invoice.
module ClientInvoices
  class Money < ApplicationService
    def initialize(invoice:, user:)
      @inv = invoice
      @user = user
    end

    def pay!(amount:, method: nil, paid_on: nil, reference: nil)
      issued!
      amount = amount.to_d
      raise Error, "Enter the amount received" unless amount.positive?
      raise Error, "More than the balance of #{money(@inv.balance)}" if amount > @inv.balance + 0.005
      raise Error, "Pick how it was paid" unless ClientInvoicePayment::METHODS.include?(method)

      @inv.payments.create!(paid_on: paid_on.presence || Date.current, amount:, method:, reference:, recorded_by: @user)
    end

    def credit!(amount:, reason:)
      issued!
      amount = amount.to_d
      raise Error, "Enter the credit amount" unless amount.positive?
      raise Error, "More than the balance of #{money(@inv.balance)}" if amount > @inv.balance + 0.005
      raise Error, "Enter the reason" if reason.to_s.strip.empty?

      ClientInvoice.create!(company_id: @inv.company_id, kind: "credit_note", status: "issued", invoice: @inv, client: @inv.client,
                            client_site: @inv.client_site, bill_to_name: @inv.bill_to_name, bill_to_uen: @inv.bill_to_uen,
                            bill_to_address: @inv.bill_to_address, attention: @inv.attention, issued_on: Date.current, terms_days: 0,
                            subtotal: amount, total: amount, reason: reason.squish, number: Finance::Numbering.next!("cn"),
                            issued_at: Time.current, issued_by: @user, created_by: @user, gst_on: false, gst_mode: @inv.gst_mode)
    end

    # Email: to / cc default to the billing people (To / CC). Nothing is sent yet; the send is recorded.
    def send!(to: nil, cc: nil)
      issued!
      people = (@inv.client_site&.own_billing? ? @inv.client_site : @inv.client).billing_contacts.select(&:email)
      to = Array(to).compact_blank.presence || people.select(&:send_to?).map(&:email)
      cc = Array(cc).compact_blank.presence || people.select(&:send_cc?).map(&:email)
      raise Error, "Add who the invoice goes To in Billing Details" if to.empty?

      @inv.sends.create!(to_emails: to, cc_emails: cc, sent_by: @user)
    end

    private

    def issued!
      raise Error, "Only an issued invoice can take this" unless @inv.invoice? && @inv.issued?
    end

    def money(v) = "S$#{format('%.2f', v)}"
  end
end
