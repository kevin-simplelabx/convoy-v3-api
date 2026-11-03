# Draft (or draft again) a school's bills for a billing period: the bills already issued stay as they are; every other
# payer gets a fresh draft bill (no number yet) from SchoolBills::Draft, and the run records what was left out.
module SchoolBills
  class Run < ApplicationService
    def initialize(year, index, user: nil, now: Time.current)
      @year = year
      @school = year.school
      @index = index.to_i
      @user = user
      @now = now
    end

    def call
      d = Draft.call(@year, @index)
      raise Error, d[:error] if d[:error]

      ApplicationRecord.transaction do
        bills = SchoolBill.where(school: @school, academic_year: @year, kind: "period", period_index: @index)
        bills.drafts.destroy_all
        issued = bills.issued.to_a
        d[:bills].each do |b|
          next if issued.any? { same_payer?(it, b) }

          write(b, d)
        end
        run = SchoolBillRun.find_or_initialize_by(school: @school, academic_year: @year, period_index: @index)
        run.update!(label: d[:period][:label], due_on: d[:due_on], skipped: d[:skipped], unlinked: d[:unlinked], auto: @user.nil?,
                    drafted_at: @now, drafted_by: @user)
        run
      end
    end

    private

    def same_payer?(bill, b) = b[:payer] == "school" ? bill.payer == "school" : bill.family_id == b[:family].id

    def write(b, d)
      to = b[:payer] == "school" ? SchoolBills.school_to(@school, @year) : SchoolBills.family_to(b[:family])
      bill = SchoolBill.create!(school: @school, academic_year: @year, kind: "period", status: "draft", payer: b[:payer], family: b[:family],
                                period_index: @index, period_label: d[:period][:label], period_starts_on: d[:period][:starts_on],
                                billing_month: d[:period][:month], issued_on: @now.to_date, due_on: d[:due_on], drafted_at: @now,
                                subtotal: b[:amount], total: b[:amount], created_by: @user, **to)
      b[:lines].each_with_index do |l, i|
        bill.lines.create!(position: i, rid: l[:rid], child_name: l[:child_name], description: l[:description], amount: l[:amount], note: l[:note])
      end
    end
  end
end
