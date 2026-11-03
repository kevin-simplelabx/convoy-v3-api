# Issue drafted bills of a period: each gets its INV number and GST (Finance Settings), and takes off the payer's credit
# notes waiting for their next bill. A school bill (the school pays) needs the school linked to a Managed Client, whose
# billing details it carries. Parents see their bills in the Convoy App; the school in the Client Portal.
module SchoolBills
  class Issue < ApplicationService
    def initialize(year, index, bill_ids: nil, user:, now: Time.current)
      @year = year
      @school = year.school
      @index = index.to_i
      @bill_ids = bill_ids&.map(&:to_i)
      @user = user
      @now = now
    end

    def call
      drafts = SchoolBill.drafts.where(school: @school, academic_year: @year, kind: "period", period_index: @index).includes(:lines, :family)
      drafts = drafts.where(id: @bill_ids) if @bill_ids
      drafts = drafts.to_a
      raise Error, "No drafted bills to issue" if drafts.empty?
      if drafts.any? { it.payer == "school" } && @school.client.nil?
        raise Error, "Link this school to a Managed Client first (Managed Clients, This Client Is a School), so the bill has its billing details"
      end

      settings = FinanceSetting.current
      credits = SchoolDocument.carried.where(school: @school).order(:issued_on, :id).to_a
      ApplicationRecord.transaction do
        drafts.each { issue(it, settings, credits) }
      end
      drafts
    end

    private

    def issue(bill, settings, credits)
      mine = credits.select { bill.payer == "school" ? it.payer == "school" : it.family_id == bill.family_id }
      credits.reject! { mine.include?(it) }
      base = bill.lines.sum(&:amount)
      split = FinanceSetting.split(base, on: settings.gst_on?, rate: settings.gst_rate, mode: settings.gst_mode)
      used = mine.sum(&:total)
      mine.each_with_index do |cn, i|
        bill.lines.create!(position: 1000 + i, description: "Credit from #{cn.number}", amount: -cn.total, credit_note: cn)
        cn.update!(applied_bill: bill)
      end
      to = bill.payer == "school" ? SchoolBills.school_to(@school, @year) : SchoolBills.family_to(bill.family)
      bill.update!(status: "issued", number: Finance::Numbering.next!("inv", date: @now.to_date, settings:), issued_on: @now.to_date, issued_at: @now,
                   issued_by: @user, subtotal: split[:sub], gst_rate: settings.gst_on? ? settings.gst_rate : 0, gst_amount: split[:gst],
                   total: [ split[:total] - used, 0.to_d ].max.round(2), **to)
    end
  end
end
