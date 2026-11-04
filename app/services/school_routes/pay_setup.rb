# Route Plans › route drawer price card (port of the prototype's setPricing for BA / sub): Bus Attendant Required and BA
# Provided By for this route (a value equal to the school's default is saved as empty, so it follows the school), the BA
# price (finance; empty = the default for the bus size and provider; changing the provider clears it), and for a route
# with no bus, who is paid for it: our own buses or a transport operator (empty = Not assigned).
module SchoolRoutes
  class PaySetup < ApplicationService
    def initialize(route, params, money: false)
      @route = route
      @p = params
      @money = money
    end

    def call
      policy = @route.school.attendant_policy || @route.school.build_attendant_policy
      r = @route
      if @p.key?(:attendant_required)
        req = ActiveModel::Type::Boolean.new.cast(@p[:attendant_required])
        r.attendant_required = req == policy.needed_sizes.include?(r.bus_type) ? nil : req
      end
      if @p.key?(:attendant_provided_by)
        by = @p[:attendant_provided_by].presence
        r.attendant_price = nil if by != (r.attendant_provided_by || policy.provided_by)
        r.attendant_provided_by = by == policy.provided_by ? nil : by
      end
      if @p.key?(:attendant_price)
        raise Error, "Needs the Fares & Billing permission" unless @money

        r.attendant_price = @p[:attendant_price].presence
      end
      if @p.key?(:pay_to)
        to = @p[:pay_to].presence
        r.assign_attributes(pay_to: to, pay_to_operator: to == "operator" ? Operator.kept.find_by(id: @p[:pay_to_operator_id]) : nil)
      end
      r.save!
      r
    end
  end
end
