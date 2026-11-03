# School Bus › School Finance: bills to families and schools, their payments and documents.
module SchoolBills
  module_function

  # When a bill for a period starting on a day is due, per the Payment & Refund Policy: days before the period starts,
  # or a day of the month the period starts in (up to the 28th). 14 days before when there is no policy.
  def due_on(policy, start)
    return start - 14 unless policy
    return start.change(day: policy.due_day.clamp(1, 28)) if policy.due_rule == "day"

    start - policy.due_days_before
  end

  # Who a family's bill goes to: the family, its code and the first guardian's email.
  def family_to(family)
    { bill_to: family.name, bill_to_code: family.code, bill_to_email: family.guardians.first&.email, client_id: nil }
  end

  # Who a school's bill goes to: its Managed Client (billing name and the first Send Invoices To email), else the Bill To
  # of the year's Bus Fares.
  def school_to(school, year)
    if (c = school.client)
      email = c.billing_contacts.find { it.send_as == "to" && it.email.present? }&.email || c.email
      return { bill_to: c.name, bill_to_code: c.code, bill_to_email: email, client_id: c.id }
    end

    table = year.fare_table
    { bill_to: table&.bill_to_name.presence || school.name, bill_to_code: nil, bill_to_email: table&.bill_to_email, client_id: nil }
  end

  # The billing period shown first: the first billed from next month, else from this month, else the last.
  def current_index(year, today = Date.current)
    months = FareTables.bill_months(year, year.fare_table)
    nxt = today.next_month.beginning_of_month
    months.index { it && it >= nxt } || months.index { it && it >= today.beginning_of_month } || (months.size - 1)
  end
end
