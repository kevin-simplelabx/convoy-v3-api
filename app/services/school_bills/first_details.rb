# What the first invoice of a bus request shows besides the money: the family (and its bill-to code) and the one line,
# the child's first month. Written by Accept with the invoice and by `school_bills:backfill_first_details` for invoices
# issued before it did. Returns true when something changed.
module SchoolBills
  class FirstDetails < ApplicationService
    # A renewing child is already in a family of the school.
    def self.family_of(req)
      req.family || (rider = req.school_rider) && FamilyRider.find_by(school: req.school, rid: rider.rid)&.family
    end

    def initialize(bill, req = bill.bus_request)
      @bill = bill
      @req = req
    end

    def call
      family = self.class.family_of(@req)
      @bill.assign_attributes(family: family || @bill.family, bill_to_code: family&.code || @bill.bill_to_code)
      changed = @bill.changed?
      @bill.save! if changed
      line_changed = write_line
      changed || line_changed
    end

    private

    def write_line
      line = @bill.lines.first || @bill.lines.build
      line.assign_attributes(rid: @req.school_rider&.rid, child_name: @req.child_name, amount: @bill.subtotal,
                             description: "#{@req.child_name} | First month, #{@bill.period_label}")
      return false unless line.new_record? || line.changed?

      line.save!
    end
  end
end
