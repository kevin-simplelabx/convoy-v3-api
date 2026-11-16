# Convoy App › Change of Address (3 steps).
module Api
  module V1
    module ConvoyApp
      class SchoolAddressChangesController < SchoolBaseController
        # GET /app/school/address_change?dependant_ids[]= → { home, children: [kid], rule, dates: [allowed], default_on }
        #   dependant_ids narrows the rule to those children (the strictest of their schools); default: every child.
        def show
          kids = ::ConvoyApp::Parents::AddressChange.kids(household)
          picked = Array(params[:dependant_ids]).map(&:to_i)
          use = picked.any? ? kids.select { picked.include?(it.dependant.id) } : kids
          today = use.any? ? ::ConvoyApp::Parents.within(use.first.company) { Date.current } : Date.current
          rule = ::ConvoyApp::Parents::AddressChange.rule(use, today)
          dates = ::ConvoyApp::Parents::AddressChange.dates(rule)
          render json: { data: { home: { block: household.block, street: household.street, floor: household.floor, unit: household.unit, postal: household.postal,
                                         address: household.address },
                                 children: kids.map { kid_json(it) },
                                 rule: { notice_days: rule.lead, start: rule.start, max_days: rule.max, from: rule.from, to: rule.to },
                                 dates:, default_on: dates.first } }
        end

        # POST /app/school/address_change/review { address_change } → per child old / new address, what moves, fare now / estimate
        def review
          render json: { data: ::ConvoyApp::Parents::AddressChange.call(member: current_member, params: change_params, preview: true) }
        end

        # POST /app/school/address_change { address_change: { postal, block, street, floor, unit, move_on, update_home, children: [{ dependant_id, am, pm }] } }
        #   → 201 [request]
        def create
          reqs = ::ConvoyApp::Parents::AddressChange.call(member: current_member, params: change_params)
          render json: { data: present_all(reqs) }, status: :created
        end

        private

        def change_params
          params.expect(address_change: [ :postal, :block, :street, :floor, :unit, :move_on, :update_home, { children: [ %i[dependant_id am pm] ] } ])
        end

        def kid_json(k)
          { dependant_id: k.dependant.id, name: k.dependant.name, school: k.school.name, company: ::ConvoyApp::Parents.company_json(k.company),
            sessions: { "both" => %w[am pm], "am" => %w[am], "pm" => %w[pm] }[k.service], riding: k.rider.present?, current_fare: k.current_fare }
        end
      end
    end
  end
end
