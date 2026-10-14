module Api
  module V1
    class UsersController < BaseController
      before_action :require_company!
      before_action -> { require_read_permission!("users") }, only: [:index]
      before_action -> { require_permission!("users") }, only: [:create, :update]

      # GET /api/v1/users
      def index
        render json: UserBlueprint.render(User.where(company_id: current_company.id))
      end

      # POST /api/v1/users
      def create
        p = params.permit(:name, :email, :password, permissions: [])
        return render_error("Fill in name, email and password") if p.values_at(:name, :email, :password).any?(&:blank?)
        return render_error("Password needs at least 8 characters") if p[:password].length < 8
        return render_error("That email already has an account") if User.exists?(email: p[:email].downcase.strip)

        perms = Array(p[:permissions]) & User::ALL_PERMISSIONS
        user = User.create!(
          name:        p[:name].strip,
          email:       p[:email].strip,
          password:    p[:password],
          role:        perms.sort == User::ALL_PERMISSIONS.sort ? "admin" : "user",
          permissions: perms,
          company:     current_company
        )
        render json: UserBlueprint.render(user), status: :created
      end

      # PUT /api/v1/users/:id
      def update
        user = User.find_by(id: params[:id], company_id: current_company.id)
        return render_error("User not found", :not_found) unless user

        perms = Array(params[:permissions]) & User::ALL_PERMISSIONS
        if user.id == current_user.id && !perms.include?("users")
          return render_error("You cannot remove your own Users permission")
        end

        user.update!(
          permissions: perms,
          role:        perms.sort == User::ALL_PERMISSIONS.sort ? "admin" : "user"
        )
        render json: UserBlueprint.render(user)
      end
    end
  end
end
