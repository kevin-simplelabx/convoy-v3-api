# Base of the Convoy App School Bus calls: the signed-in adult's Family (any adult may look and send requests; money stays
# with the Billing Contact). A request is found among the Family's own requests only, inside its company.
module Api
  module V1
    module ConvoyApp
      class SchoolBaseController < HouseholdBaseController
        private

        def billing? = ::ConvoyApp::Parents.billing?(current_member)

        # Yields the Family's request with this id inside its company (404 when it is not theirs).
        def with_request(id)
          ::ConvoyApp::Parents.companies(household).each do |company|
            found = ::ConvoyApp::Parents.within(company) do
              req = BusRequest.from_household(household).includes(:registration_bill, :answer_moves, academic_year: :registration, school: :company, first_bill: :payments)
                              .find_by(id:)
              req && [ yield(req) ]
            end
            return found.first if found
          end
          raise ActiveRecord::RecordNotFound
        end

        def present(req) = ::ConvoyApp::Parents::Present.call(req, billing: billing?)

        # Requests just written (in several companies): each presented inside its own company.
        def present_all(reqs)
          reqs.map { |r| ::ConvoyApp::Parents.within(r.company) { present(BusRequest.includes(:registration_bill, academic_year: :registration, school: :company).find(r.id)) } }
        end
      end
    end
  end
end
