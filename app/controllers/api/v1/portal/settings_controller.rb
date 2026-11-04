# Client Portal › Settings: Logo and Colour, Sites (read only, kept by the transport company), Billing Details.
module Api
  module V1
    module Portal
      class SettingsController < AppController
        # GET /portal/settings/sites
        def sites
          authorize_portal :settings, :sites?
          render json: { data: ::Portal::Sites.call(client_user: current_client_user) }
        end

        # PATCH /portal/settings/brand (multipart) { logo (file), remove_logo: true, color: "#004F59" | "" }
        def brand
          authorize_portal :settings, :brand?
          client = current_client
          client.brand_logo = params[:logo] if params[:logo].present?
          client.remove_brand_logo! if ActiveModel::Type::Boolean.new.cast(params[:remove_logo])
          client.brand_color = params[:color] if params.key?(:color)
          client.save!
          render json: { data: client.decorate.brand_info }
        end

        # GET /portal/settings/billing
        def billing
          authorize_portal :settings, :billing?
          render json: { data: ::Portal::BillingDetails.list(current_client_user) }
        end

        # PATCH /portal/settings/billing/organisation { billing: { legal_name, uen, billing_email, attention, billing_address } }
        def organisation_billing
          authorize_portal :settings, :organisation_billing?
          render json: { data: ::Portal::BillingDetails.call(billable: current_client, params: billing_params) }
        end

        # PATCH /portal/settings/billing/sites/:id { billing: { … } }
        def site_billing
          site = authorize(current_client.sites.find(params[:id]), :site_billing?, policy_class: ::Portal::SettingsPolicy)
          render json: { data: ::Portal::BillingDetails.call(billable: site, params: billing_params) }
        end

        private

        def billing_params = params.expect(billing: %i[legal_name uen billing_email attention billing_address])
      end
    end
  end
end
