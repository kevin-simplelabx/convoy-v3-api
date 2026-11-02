# Countries a company can run in (Company Settings > Country, Request a Country Change). Only live ones can be picked.
module Api
  module V1
    class CountriesController < BaseController
      skip_before_action :assign_tenant
      skip_after_action :verify_authorized

      def index
        render json: { data: CountryBlueprint.render_as_hash(Country.all) }
      end
    end
  end
end
