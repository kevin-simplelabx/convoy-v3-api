# Base for every API endpoint: signed-in user, company (tenant) scoping, company timezone, Pundit, JSON errors.
module Api
  module V1
    class BaseController < ApplicationController
      include ErrorHandling
      include Paginated
      include Pundit::Authorization

      set_current_tenant_through_filter

      before_action :authenticate!
      before_action :assign_tenant
      around_action :use_company_time_zone
      after_action :verify_authorized

      private

      def authenticate!
        raise Unauthenticated unless current_user&.active_for_authentication?
      end

      # A company user works in their own company; a Convoy Admin in the company picked for the session.
      def current_company
        return @current_company if defined?(@current_company)

        @current_company =
          if current_user.nil? then nil
          elsif current_user.convoy_admin? then session[:company_id] && Company.find_by(id: session[:company_id])
          else current_user.company
          end
      end

      def assign_tenant
        set_current_tenant(current_company)
      end

      def use_company_time_zone(&)
        Time.use_zone(current_company&.timezone || Time.zone, &)
      end

      def render_data(object, blueprint, status: :ok, **options)
        render json: { data: blueprint.render_as_hash(present(object), **options) }, status:
      end

      # Decorate a record or collection when its model has a decorator.
      def present(object)
        model = object.respond_to?(:klass) ? object.klass : object.class
        model.respond_to?(:decorator_class?) && model.decorator_class? ? object.decorate : object
      end
    end
  end
end
