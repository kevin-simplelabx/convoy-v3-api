# One-off backfill (`school_bills:backfill_first_details`): first invoices issued before they carried a line, the
# family and the bill-to code get them through SchoolBills::FirstDetails. Money, number, status and dates stay as
# issued. Safe to run again: a bill that already has its details is left alone. `dry_run` counts without writing.
module SchoolBills
  class BackfillFirstDetails < ApplicationService
    Result = Struct.new(:checked, :updated, :skipped, keyword_init: true)

    def initialize(dry_run: false)
      @dry_run = dry_run
    end

    def call
      ::Company.find_each.to_h { |company| [ company.code, ActsAsTenant.with_tenant(company) { run } ] }
    end

    private

    def run
      result = Result.new(checked: 0, updated: 0, skipped: 0)
      missing.includes(:lines, :family, bus_request: %i[family school_rider]).find_each do |bill|
        result.checked += 1
        req = bill.bus_request
        next result.skipped += 1 if req.nil? || bill.period_label.blank?

        updated = @dry_run ? needs?(bill, req) : ApplicationRecord.transaction { FirstDetails.call(bill, req) }
        updated ? result.updated += 1 : result.skipped += 1
      end
      result
    end

    # First invoices of a request with no line, no family or no bill-to code.
    def missing
      SchoolBill.where(kind: "first").where.not(bus_request_id: nil)
                .where("family_id IS NULL OR bill_to_code IS NULL OR NOT EXISTS (SELECT 1 FROM school_bill_lines l WHERE l.school_bill_id = school_bills.id)")
    end

    def needs?(bill, req)
      family = FirstDetails.family_of(req)
      bill.lines.empty? || (family && (bill.family_id != family.id || bill.bill_to_code != family.code))
    end
  end
end
