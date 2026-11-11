# School Finance sample for St. Stephen's School: riders on the Term 4 routes (AY 2026) with their families (two left
# without one), the Term 4 family bills drafted and issued (one paid by PayNow with its receipt, one part paid, one past
# due with its late fee partly waived, one with a credit note carried to the next bill, one still a draft), and last
# month's operator pay run for Hup Seng Coaches (its routes priced, a taxi claim) sent to Finance.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  fin = User.find_by!(email: "finance@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  year = school.academic_years.find_by!(key: "2026")
  plans = school.plans.where(session: %w[am pm], in_use: true).includes(routes: :stops).to_a

  if SchoolRouteRider.joins(school_route: :plan).where(school_plans: { school_id: school.id }).none?
    everyone = SchoolRider.of_school_on(school, Date.new(2026, 9, 14)).order(:rid).to_a
    # Each stop's riders are the students living at it (Year Setup sample): riders_count of the stop, fewer on PM for those without a PM ride.
    plans.each do |plan|
      plan.routes.each do |route|
        route.stops.each do |stop|
          here = everyone.select { it.address.to_s.start_with?("#{stop.name} #") && (plan.session == "am" || it.pm) }
          here.each { SchoolRouteRider.create!(school_route: route, stop:, rid: it.rid) }
          stop.update_columns(riders_count: here.size)
        end
        route.update_columns(riders_count: route.stops.sum { it.riders.count })
      end
    end
    # PUDO points for the AM riders (Stop Assignment), as the daily job does when the plan starts.
    plans.select { it.session == "am" }.each do |plan|
      plan.update_columns(riders_assigned_at: nil)
      Plans::AssignRiders.call(plan)
    end
    riders = everyone.first(18)
    linked = FamilyRider.where(school:, rid: riders.map(&:rid)).pluck(:rid)
    riders.reject { linked.include?(it.rid) }[0...-2].each_slice(2) do |pair|
      last = pair.first.name.split.first
      fam = school.families.create!(code: Family.next_code(school), name: "#{last.upcase} Family", name_mode: "custom", sample: true)
      fam.guardians.create!(first_name: "Parent", last_name: last, relationship: "Mother", email: "#{last.downcase}.family@mail.sg", phone: "+65 9#{rand(1_000_000..9_999_999)}")
      pair.each { FamilyRider.create!(family: fam, school:, rid: it.rid) }
    end
  end

  unless SchoolBillRun.exists?(school:, academic_year: year, period_index: 3)
    SchoolBills::Run.call(year, 3, user: fin)
    drafts = SchoolBill.drafts.where(school:, academic_year: year, period_index: 3).order(:bill_to).to_a
    SchoolBills::Issue.call(year, 3, bill_ids: drafts[0...-1].map(&:id), user: fin)
    bills = SchoolBill.issued.where(id: drafts.map(&:id)).order(:bill_to).includes(:lines, :payments, :waivers, :notes).to_a
    if bills.size >= 4
      due = bills.first.due_on
      SchoolBills::RecordPayment.call(school, [ [ bills[0], bills[0].total ] ], paid_on: due - 2, method: "PayNow", reference: "PN-88213", user: fin)
      SchoolBills::RecordPayment.call(school, [ [ bills[1], (bills[1].total / 2).round(2) ] ], paid_on: due + 5, method: "Bank Transfer", user: fin)
      bills[2].waivers.create!(kind: "late", amount: 10, reason: "First late payment this year", created_by: fin)
      SchoolBills::AddNote.call(bills[3].reload, { doc_type: "cn", description: "Bus did not run on 2 days", amount: 40, reason: "Breakdown in October",
                                                   credit_use: "carry" }, user: fin)
    end
  end

  unless SchoolPayout.exists?(school:)
    op = Operator.find_by(name: "Hup Seng Coaches")
    routes = plans.flat_map(&:routes).select { it.vehicle_changes.includes(:vehicle).any? { |c| c.vehicle&.operator_id == op&.id } }
    if op && routes.any?
      routes.each do |r|
        r.prices.find_or_create_by!(effective_from: r.plan.effective_from) { it.assign_attributes(mode: "fixed", monthly: 4800, created_by: admin) }
      end
      month = Date.current.prev_month.beginning_of_month
      acts = SchoolPay::Actions.new(school, month, op, user: fin)
      acts.add_line({ kind: "Taxi claim", adj_on: (month + 9).iso8601, route: routes.first.label, amount: "38.50",
                      reason: "Bus broke down, two riders sent home by taxi" })
      acts.invoice_number("HSC-#{month.strftime('%y%m')}-014")
      acts.send_to_finance
    end
  end
end
