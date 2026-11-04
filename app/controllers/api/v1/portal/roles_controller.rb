# Role Permissions window: the seven roles and what each can do (the prototype's table, rows not built yet included).
module Api
  module V1
    module Portal
      class RolesController < AppController
        # GET /portal/roles
        def index
          authorize_portal :shell, :show?
          render json: { data: { roles:, features: } }
        end

        private

        def roles
          ClientUser::ROLES.map { |key, r| { key:, label: r[:label], tag: r[:tag], wide: r[:wide], gives: ClientUserAccess::GIVES.fetch(key, []) } }
        end

        def features
          ClientUserAccess::FEATURES.map do |group, rows|
            { group:, features: rows.map { |name, detail, roles| { name:, detail:, roles: } } }
          end
        end
      end
    end
  end
end
