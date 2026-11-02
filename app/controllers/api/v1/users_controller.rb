# Settings > Users: list with status counts, Add User, Edit (permissions, Super Admin, schools), Suspend / Turn back on,
# Delete (soft), and the role presets for Start From a Role / View Role Permissions.
module Api
  module V1
    class UsersController < BaseController
      def index
        authorize User
        scope = policy_scope(User)
        counts = scope.group(:status).count
        scope = scope.where(status: params[:status]) if params[:status].in?(User.statuses.keys)
        scope = scope.includes(:schools, :created_by).ransack(ransack_params).result.order(:name)
        render_page scope, UserBlueprint, view: :manage, actor: current_user,
                                          meta: { counts: { all: counts.values.sum, active: counts["active"].to_i, suspended: counts["suspended"].to_i } }
      end

      def show
        render_user authorize(find_user)
      end

      # GET /users/roles — Start From a Role presets and the permission list.
      def roles
        authorize User
        render json: {
          data: {
            permissions: User::PERMISSIONS.map { |id| { id:, label: User::PERMISSION_LABELS.fetch(id) } },
            roles: User::ROLE_PRESETS.map do |r|
              r.slice(:id, :name, :tag, :permissions).merge(owner: !!r[:owner], all_permissions: r[:permissions].size == User::PERMISSIONS.size)
            end
          }
        }
      end

      def create
        authorize User
        user = Users::Save.call(actor: current_user, company: current_company, params: permitted_attributes(User))
        render_user user, status: :created
      end

      def update
        user = authorize find_user
        render_user Users::Save.call(actor: current_user, company: current_company, user:, params: permitted_attributes(user))
      end

      def suspend = act(:suspend)
      def activate = act(:activate)

      def destroy
        user = authorize find_user
        Users::Act.call(actor: current_user, user:, action: :remove)
        head :no_content
      end

      private

      def find_user = policy_scope(User).find(params[:id])

      def act(action)
        user = authorize find_user
        render_user Users::Act.call(actor: current_user, user:, action:)
      end

      def render_user(user, status: :ok)
        render_data user.reload, UserBlueprint, view: :manage, actor: current_user, status:
      end
    end
  end
end
