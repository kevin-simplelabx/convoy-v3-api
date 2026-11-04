# Client Invoices > the invoice dialog on a draft: bill-to, attention, PO, date, terms, notes, GST mode (draft only),
# manual lines (the whole list), lines removed (their runs go back to Ready to Invoice), late cancellation runs
# billed or waived. Then Issue (numbered), Void (issued with no payments: runs go back) or delete the draft.
module ClientInvoices
  class Edit < ApplicationService
    FIELDS = %i[bill_to_name bill_to_uen bill_to_address attention po issued_on terms_days notes gst_mode].freeze

    def initialize(invoice:, user:)
      @inv = invoice
      @user = user
    end

    def update(params)
      raise Error, "Only drafts can be changed" unless @inv.draft?

      ClientInvoice.transaction do
        @inv.update!(params.slice(*FIELDS))
        @inv.lines.where(id: Array(params[:remove_line_ids])).where.not(source: "manual").destroy_all if params.key?(:remove_line_ids)
        save_manual(params[:manual_lines]) if params.key?(:manual_lines)
        edit_lines(params[:lines]) if params.key?(:lines)
        if params.key?(:waived_run_ids)
          ids = Array(params[:waived_run_ids]).map(&:to_i)
          @inv.runs.where(client_invoice_lines: { source: "late_cancel" }).find_each { |r| r.update!(waived: ids.include?(r.id)) }
        end
        @inv.lines.reset
        @inv.recalculate!
      end
      @inv
    end

    def issue!
      raise Error, "Only drafts can be issued" unless @inv.draft?
      raise Error, "Add at least one line" if @inv.lines.empty?
      raise Error, "Enter who the invoice is billed to" if @inv.bill_to_name.blank?

      date = @inv.issued_on || Date.current
      @inv.update!(status: "issued", issued_on: date, due_on: date + @inv.terms_days, number: Finance::Numbering.next!("inv", date:),
                   issued_at: Time.current, issued_by: @user, audit_comment: "Issued")
      @inv
    end

    def void!
      raise Error, "Only issued invoices can be voided" unless @inv.issued? && @inv.invoice?
      raise Error, "#{@inv.number} has payments. Use a credit note instead" if @inv.payments.any?

      ClientInvoice.transaction do
        @inv.update!(status: "void", voided_at: Time.current, voided_by: @user, audit_comment: "Voided")
        ClientInvoiceLineRun.where(client_invoice_line_id: @inv.lines.select(:id)).update_all(active: false) # rubocop:disable Rails/SkipsModelValidations
      end
      @inv
    end

    def destroy!
      raise Error, "Only drafts can be deleted" unless @inv.draft?

      @inv.destroy!
    end

    private

    TEXT = %i[ref description details period_text].freeze

    # Trip and late cancellation lines as typed on the draft: Trip ID, description, period, details; a trip line's amount and
    # quantity too (kept; the unit price goes, it no longer adds up). An empty amount goes back to the runs' total. A late
    # cancellation line's amount always comes from its runs ("From runs").
    def edit_lines(list)
      Array(list).each do |l|
        l = l.to_h.symbolize_keys
        line = @inv.lines.where.not(source: "manual").find(l[:id])
        line.assign_attributes(l.slice(*TEXT).transform_values { it.to_s.strip })
        if line.from_trip? && l.key?(:amount)
          if l[:amount].blank?
            line.assign_attributes(amount_overridden: false, unit_price: line.billed_runs.map(&:amount).uniq.one? ? line.billed_runs.first.amount : nil)
          else
            line.assign_attributes(amount_overridden: true, amount: l[:amount].to_d, quantity: (l[:quantity].presence || line.quantity).to_d, unit_price: nil)
          end
        end
        line.save!
      end
    end

    def save_manual(list)
      @inv.lines.from_manual.destroy_all
      next_pos = @inv.lines.maximum(:position).to_i
      Array(list).each do |l|
        l = l.to_h.symbolize_keys
        qty = (l[:quantity].presence || 1).to_d
        amount = l[:amount].presence&.to_d || (qty * l[:unit_price].to_d)
        @inv.lines.create!(source: "manual", ref: l[:ref].presence, description: l[:description], details: l[:details], period_text: l[:period_text],
                           quantity: qty, unit_price: l[:unit_price].presence, amount:, position: next_pos += 1)
      end
    end
  end
end
