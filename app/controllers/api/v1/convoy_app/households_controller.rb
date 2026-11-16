# Convoy App › Household: Set Up Your Family (postal search, create), the Household screen and Delete Family. The screen
# answers `data: null` while the person has no Family (Home shows "Set Up Your Family").
module Api
  module V1
    module ConvoyApp
      class HouseholdsController < HouseholdBaseController
        skip_before_action :require_household!, only: %i[show create postal options]
        before_action :require_admin!, only: :destroy

        # GET /app/household
        def show
          return render json: { data: nil } unless current_member

          render_household
        end

        # POST /app/household { household: { name, postal, block, street, floor, unit, line2, billing_same, billing_address,
        #   billing_contact (I am the Billing Contact, default true), relationship (how the creator is related: Mother, Father...) } }
        # → the Household (the person becomes its Admin)
        def create
          household = ::ConvoyApp::Households::Create.call(account: current_account, params: create_params)
          @current_member = household.members.find_by!(app_account_id: current_account.id)
          render_household(status: :created)
        end

        # DELETE /app/household — Delete Family (Admin only; 422 family_blocked with details.reasons while a child has a service,
        # an accepted request or an unpaid bill)
        def destroy
          ::ConvoyApp::Households::Delete.call(household:)
          render json: { data: { deleted: true } }
        end

        # GET /app/household/postal?postal=123456 → { found, block, street, address, lat, lng } | { found: false, message }
        def postal
          render json: { data: ::ConvoyApp::Households::PostalSearch.call(postal: params[:postal]) }
        end

        # GET /app/household/options → lists for the Set Up Your Family and Add a Child forms
        def options
          render json: { data: { relationships: HouseholdMember::RELATIONSHIPS, medical_tags: Dependant::MEDICAL_TAGS,
                                 genders: Dependant::GENDERS, level_year: Date.current.year + 1,
                                 default_levels: ::ConvoyApp::SchoolDirectory::DEFAULT_LEVELS, schools: ::ConvoyApp::SchoolDirectory.call } }
        end

        private

        def create_params
          params.expect(household: %i[name postal block street floor unit line2 billing_same billing_address billing_contact relationship])
        end
      end
    end
  end
end
