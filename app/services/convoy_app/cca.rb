# Convoy App › CCA Bus per ride: the schools where the Family has a child riding and the CCA / ASA bus is charged per ride
# (OS CCA Rides on, price above 0), the Family copy at each, and the helpers the CCA screens share. Every read and write runs
# inside the school's company and time zone (Parents.within), so "today" and the Saturday 23:59 cut-off are the company's.
module ConvoyApp
  module Cca
    Offer = Data.define(:company, :school, :family, :setting, :kids)
    Kid = Data.define(:dependant, :rider)

    DOW = %w[_ Mon Tue Wed Thu Fri Sat Sun].freeze
    NOTE = "Paid rides cannot be removed. Not Riding tells the bus not to wait, and the ride is still charged. A ride the bus does not run becomes credit."

    module_function

    # One offer per school (inside its company), the Family's riding children with a school rider each.
    def offers(household)
      deps = household.dependants.index_by(&:id)
      Parents.companies(household).flat_map do |company|
        Parents.within(company) do
          Family.where(household_id: household.id).includes(school: :cca_ride_setting).filter_map do |family|
            school = family.school
            setting = school.cca_ride_setting
            next unless setting&.enabled && setting.price.positive?

            kids = kids_of(family, school, deps)
            Offer.new(company:, school:, family:, setting:, kids:) if kids.any?
          end
        end
      end.sort_by { [ it.school.name, it.school.id ] }
    end

    # The offer for this school (404 when the Family has none there); the first one without an id.
    def offer!(household, school_id)
      list = offers(household)
      found = school_id.blank? ? list.first : list.find { it.school.id == school_id.to_i }
      found or raise ActiveRecord::RecordNotFound
    end

    # Children with a rider on the list today or later who ride: not a child whose offer waits for its first invoice
    # (Parents.pending_offer?). Inside the company.
    def kids_of(family, school, deps)
      frs = FamilyRider.where(family:).where.not(dependant_id: nil).to_a
      riders = SchoolRider.where(school_id: school.id, rid: frs.map(&:rid)).where(ends_on: [ nil, Date.current.. ]).index_by(&:rid)
      pending = Parents.pending_offer_ids(frs.map(&:dependant_id).uniq)
      frs.filter_map { |fr| !pending.include?(fr.dependant_id) && (r = riders[fr.rid]) && (d = deps[fr.dependant_id]) && Kid.new(d, r) }
         .sort_by { it.dependant.id }
    end

    # Why a child has no bus on this date (before the rider's start, after the last day), else nil.
    def outside(kid, date)
      first = kid.dependant.first_name
      r = kid.rider
      if r.starts_on && date < r.starts_on then "#{first}'s bus starts on #{r.starts_on.strftime('%-d %b')}"
      elsif r.ends_on && date > r.ends_on then "#{first}'s last bus day is #{r.ends_on.strftime('%-d %b')}"
      end
    end

    # Card: the school's ways to pay without Bank Transfer (too slow to confirm a seat), PayNow when none is left.
    def methods(school)
      list = Payments.options(school).reject { it.key == "bank" }
      list.presence || [ Payments::Option.new(key: "paynow", label: "PayNow", icon: Payments::ICONS["paynow"], fee_kind: "none", fee: 0.to_d) ]
    end

    def days_text(days)
      names = days.sort.map { DOW[it] }
      names.size > 1 ? "#{names[0..-2].join(', ')} and #{names.last}" : names.first || "No days set"
    end

    def money(value) = "S$#{format('%.2f', value)}"

    # The picks of a payment as CcaRides::Pay takes them: [{ dependant_id:, date: }] → child, class, rider, date.
    def picks(offer, raw)
      list = Array(raw).map { |p| p.respond_to?(:to_unsafe_h) ? p.to_unsafe_h : p.to_h }
      raise ApplicationService::Error, "Pick at least one day" if list.empty?

      list.map do |p|
        kid = offer.kids.find { it.dependant.id == p["dependant_id"].to_i || it.dependant.id == p[:dependant_id].to_i } or
          raise ApplicationService::Error, "Pick a child who rides this school's bus"
        date = Date.iso8601(p["date"].presence || p[:date].to_s)
        (why = outside(kid, date)) and raise ApplicationService::Error, why
        { child_name: kid.rider.name, class_name: kid.rider.grade || kid.dependant.level, school_rider: kid.rider, date: }
      end.uniq { [ it[:child_name], it[:date] ] }
    rescue Date::Error
      raise ApplicationService::Error, "Pick at least one day"
    end

    # The Home card: next week's rides, or the cut-off. nil when no school charges the CCA bus per ride.
    def card(household)
      list = offers(household)
      return if list.empty?

      first = list.first
      Parents.within(first.company) do
        s = first.setting
        today = Date.current
        next_mon = CcaRides.monday(today) + 7
        cut = CcaRides.cutoff(next_mon)
        booked = CcaBooking.where(family: first.family, date: next_mon..(next_mon + 6)).order(:date, :child_name).to_a
        names = booked.filter_map do |b|
          kid = first.kids.find { it.rider.id == b.school_rider_id || it.rider.name == b.child_name }
          "#{(kid&.dependant&.first_name || b.child_name.split.first)} #{b.date.strftime('%a')}"
        end
        { title: "CCA Bus · Next Week#{" · #{list.size} schools" if list.size > 1}", booked: names.any?, school_id: first.school.id,
          sub: names.any? ? "Booked: #{names.join(', ')}" : "Book and pay by #{CcaRides.label(cut)}, 23:59 · #{money(s.price)} a ride" }
      end
    end
  end
end
