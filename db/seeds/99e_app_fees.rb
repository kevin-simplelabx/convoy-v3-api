# Convoy App Fees and CCA Bus (Phase 5) for the Tan Family of 99d_app_school.rb at St. Stephen's School (SimpleDrive):
# - two period bills in Fees: Term 3 (paid through the app, simulated PayNow, with its receipt) and Term 4 (due next week),
#   next to Lucas's unpaid registration fee bill from 99d, so Outstanding, Invoices and Payments all have rows;
# - CCA Bus per ride (54_school_parents.rb turns it on at S$8, Tue and Thu): Ethan rode the week before last on a day the bus
#   did not run (S$8 credit), his Same Days Every Week are Tue and Thu, and one ride next week is booked through the app
#   (the credit pays it first). Dates the school calendar closes are skipped. Idempotent.
rachel = AppIdentity.find_by!(kind: "mobile", value: ConvoyApp.normalize("mobile", "+65 9188 2045")).app_account
household = rachel.household or raise "Run 99b_app_household.rb first"
member = household.members.find_by!(app_account: rachel)
ethan = household.dependants.find_by!(name: "Ethan Tan")

with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  year = school.academic_years.find_by!(key: "2026")
  family = Family.find_by(household_id: household.id, school:) or raise "Run 99d_app_school.rb first"
  rider = SchoolRider.find_by!(dependant_id: ethan.id)
  today = Date.current

  # Period bills (a line for Ethan, GST as Finance Settings).
  unless SchoolBill.exists?(family:, kind: "period")
    settings = FinanceSetting.current
    [ [ 2, "Term 3 | Jun 2026", Date.new(2026, 6, 29), today - 40, true ], [ 3, "Term 4 | Sep 2026", Date.new(2026, 9, 14), today + 7, false ] ].each do |index, label, starts, due, paid|
      split = FinanceSetting.split(420, on: settings.gst_on?, rate: settings.gst_rate, mode: settings.gst_mode)
      bill = SchoolBill.create!(school:, academic_year: year, family:, kind: "period", status: "issued", number: Finance::Numbering.next!("inv", settings:), bill_to: family.name,
                                bill_to_code: family.code, period_index: index, period_label: label, period_starts_on: starts, billing_month: starts.beginning_of_month,
                                issued_on: due - 14, issued_at: (due - 14).in_time_zone, due_on: due, due_at: due.in_time_zone, subtotal: split[:sub],
                                gst_rate: settings.gst_on? ? settings.gst_rate : 0, gst_amount: split[:gst], total: split[:total])
      bill.lines.create!(position: 0, child_name: ethan.name, rid: rider.rid, amount: 420, description: "#{ethan.name} | 0 to 3 km | 2-way")
      next unless paid

      SchoolBills::RecordPayment.call(school, [ [ bill, bill.total ] ], paid_on: due - 3, method: "PayNow", reference: "SIM-DEMO0001", user: nil, source: "app")
    end
  end

  # CCA Bus: Ethan's credit, Same Days Every Week, one ride next week paid through the app.
  setting = CcaRides.setting(school)
  if setting.enabled && setting.price.positive?
    years = school.academic_years.includes(:holidays, :special_days, :terms).to_a
    runs = ->(date) { (c = CcaRides.calendar(years, date, PublicHoliday.where(date:).index_by(&:date))).nil? || c[:run] }
    pick = ->(date) { { child_name: rider.name, class_name: rider.grade || ethan.level, school_rider: rider, date: } }

    unless CcaBooking.exists?(family:, school_rider: rider)
      before = CcaRides.monday(today) - 14 + 1
      if runs.(before) && !school.cca_off_days.exists?(date: before)
        CcaRides::Pay.call(family, picks: [ pick.(before) ], today: before - 4)
        CcaRides::NotRunning.call(school, date: before, reason: "bus", note: "Bus breakdown", user: admin)
      end
    end

    CcaStandingDay.find_or_create_by!(family:, school_rider: rider) { it.school = school; it.days = setting.days }

    next_mon = CcaRides.monday(today) + 7
    thursday = next_mon + 3
    if runs.(thursday) && !CcaBooking.exists?(family:, school_rider: rider, date: thursday)
      ConvoyApp::Cca::Pay.call(member:, school_id: school.id, picks: [ { dependant_id: ethan.id, date: thursday.iso8601 } ], method: "paynow")
    end
  end

  puts "Convoy App Fees: #{SchoolBill.where(family:).count} bills for the Tan Family, CCA credit S$#{format('%.2f', CcaRides.credit(family))}"
end
