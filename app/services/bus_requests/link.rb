# On accepting a new child: add them to the rider list (Unpaid until the first invoice is paid) from the start date and
# to a family — the school's family with a guardian of the same phone (last 8 digits) or email, else a new family with
# the parent as guardian. The family gets the first invoice too.
module BusRequests
  class Link < ApplicationService
    def initialize(req, user:)
      @req = req
      @user = user
    end

    def call
      school = @req.school
      last, *first = @req.child_name.split
      rider = SchoolRiders::Add.call(school:, user: @user, params: {
                                       first_name: first.join(" ").presence, last_name: last, name_order: "last", grade: @req.level, address: @req.address,
                                       postal: @req.postal, am: @req.am, pm: @req.pm, starts_on: @req.start_on, parent_name: @req.parent_name,
                                       parent_contact: @req.parent_phone, cca_days: @req.cca_days.map { Date::ABBR_DAYNAMES[it] },
                                       remarks: "#{@req.source == 'app' ? 'From the Convoy App' : 'Added in Convoy OS'}, #{@req.code}"
                                     })
      rider.update!(lat: @req.lat, lng: @req.lng) if rider.lat.nil? && @req.lat
      family = @req.family || match(school) || create_family(school)
      Families.link(family, school, [ rider.rid ])
      @req.update!(school_rider: rider, family:)
      if (bill = @req.first_bill)
        bill.update!(school_rider: rider, family:, bill_to_code: family.code)
        bill.lines.update_all(rid: rider.rid)
      end
      @req.log!("#{@req.child_name} added to the rider list as #{rider.rid} (Unpaid) and linked to #{family.name} (#{family.code})", by: @user)
      rider
    end

    private

    def match(school)
      tail = @req.parent_phone.to_s.gsub(/\D/, "")[-8..]
      email = @req.parent_email.to_s.strip.downcase.presence
      return unless tail || email

      rel = FamilyGuardian.joins(:family).where(families: { school_id: school.id })
      rel = tail ? rel.where("RIGHT(REGEXP_REPLACE(family_guardians.phone, '\\D', '', 'g'), 8) = ?", tail) : rel.none
      rel = rel.or(FamilyGuardian.joins(:family).where(families: { school_id: school.id }).where("LOWER(family_guardians.email) = ?", email)) if email
      rel.first&.family
    end

    def create_family(school)
      last, *first = @req.parent_name.to_s.split
      family = school.families.create!(code: Family.next_code, name: "#{(last || 'New').upcase} Family", name_mode: "custom",
                                       source: @req.source == "app" ? "app" : "console", address: @req.address, postal: @req.postal,
                                       registered_at: @req.submitted_at)
      family.guardians.create!(first_name: first.join(" ").presence, last_name: last, name_order: "last", relationship: "Parent",
                               phone: @req.parent_phone, email: @req.parent_email)
      family
    end
  end
end
