# Accepting a request sent from the Convoy App (BusRequests::Link): the app Family becomes the school's family — the one
# already linked to it at that school, else a new one named like the Family with its home address — and every active adult
# is a guardian (added once, by household member; later accepts add adults who joined since). The child is linked by
# dependant id on the family rider and the rider list. Console families are never matched by phone here (claiming one
# needs an Accept / Not Me invite, not built). Runs inside the school's company.
module ConvoyApp
  module Parents
    module LinkFamily
      RELATIONSHIPS = { "Mother" => "Mother", "Father" => "Father", "Grandparent" => "Grandparent", "Relative" => "Relative",
                        "Domestic Helper" => "Helper", "Family Friend" => "Other" }.freeze

      module_function

      def family(req)
        household = req.household or return
        school = req.school
        fam = Family.find_by(school:, household_id: household.id) ||
              school.families.create!(code: Family.next_code(school), name: household.name, name_mode: "custom", source: "app", household:,
                                      address: household.address, postal: household.postal, registered_at: req.submitted_at)
        guardians(fam, household)
        fam
      end

      def rider(req, rider)
        return unless req.dependant_id

        FamilyRider.where(school: req.school, rid: rider.rid).update_all(dependant_id: req.dependant_id)
        rider.update!(dependant_id: req.dependant_id)
      end

      def guardians(fam, household)
        have = fam.guardians.filter_map(&:household_member_id).to_set
        HouseholdMember.active.where(household:).includes(app_account: :identities).order(:id).reject { have.include?(it.id) }.each_with_index do |m, i|
          acct = m.app_account
          email = acct&.identities&.find { it.kind == "email" && it.tag == "personal" && it.verified_at }
          fam.guardians.create!(household_member: m, first_name: acct&.first_name || m.first_name, last_name: acct&.last_name,
                                name_order: acct&.name_order || "last", relationship: RELATIONSHIPS.fetch(m.relationship.to_s, "Parent"),
                                phone: m.phone, email: email&.value, position: fam.guardians.size + i, app_joined_at: m.joined_at,
                                app_joined_how: m.via_creator? ? "signup" : "invite")
        end
      end
    end
  end
end
