# Shared by Fleet > Drivers and Transport Operators > Operator Drivers: tabs with counts, invite, edit, the row buttons
# (Drivers::Act), View Details (what the driver shared) and the customer-facing name and photo.
# The including controller defines driver_class, driver_blueprint, driver_includes, driver_params and
# list_options(drivers) (blueprint options for the drivers shown).
module DriverInviteActions
  extend ActiveSupport::Concern

  # GET ?status=pending|active|declined|past&q= — meta.counts per tab (search applied, tab not).
  def index
    authorize driver_class
    scope = filtered(policy_scope(driver_class).kept)
    pagy, drivers = pagy(scope.where(status: params[:status].presence || "active").includes(*driver_includes).order(:name))
    render json: {
      data: driver_blueprint.render_as_hash(present(drivers), **list_options(drivers)),
      meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages, counts: count_tabs(scope) }
    }
  end

  def show
    driver = authorize find_driver
    render_data driver, driver_blueprint, **list_options([ driver ])
  end

  # Invite: a pending driver, the SMS recorded. Response meta.message is the text the driver receives.
  def create
    driver = authorize driver_class.new(driver_params)
    Drivers::Invite.call(driver:, user: current_user, company: current_company)
    render json: { data: driver_blueprint.render_as_hash(present(driver), **list_options([ driver ])),
                   meta: { message: driver.invites.last.message } }, status: :created
  end

  def update
    driver = authorize find_driver
    driver.update!(driver_params)
    render_data driver, driver_blueprint, **list_options([ driver ])
  end

  %w[resend accept decline reinvite remove].each do |action|
    define_method(action) do
      driver = authorize find_driver, :update?
      Drivers::Act.call(driver:, action:, user: current_user, company: current_company)
      render_data driver.reload, driver_blueprint, **list_options([ driver ])
    end
  end

  # Cancel invite (pending) / Delete (declined, past). Active drivers are removed first.
  def destroy
    driver = authorize find_driver
    Drivers::Act.call(driver:, action: "delete", user: current_user, company: current_company)
    head :no_content
  end

  # View Details: what the driver shared (null until they share), with the NRIC / FIN masked unless reveal_id=true.
  def details
    driver = authorize find_driver, :show?
    kyc = driver.kyc_profile
    reveal = ActiveModel::Type::Boolean.new.cast(params[:reveal_id])
    kyc&.audits&.create!(action: "update", comment: "Full #{kyc.id_label} shown", user: current_user) if reveal && kyc
    render json: { data: { driver: driver_blueprint.render_as_hash(present(driver), **list_options([ driver ])),
                           kyc: kyc && DriverKycProfileBlueprint.render_as_hash(kyc, reveal:) } }
  end

  # Shown to Your Customers: PATCH { display_name, display_photo (file), remove_display_photo } — both empty clears it.
  def set_display
    driver = authorize find_driver, :update?
    p = params.permit(:display_name, :display_photo, :remove_display_photo)
    driver.set_display!(name: p[:display_name], photo: p[:display_photo], remove_photo: p[:remove_display_photo], user: current_user)
    render_data driver, driver_blueprint, **list_options([ driver ])
  end

  private

  def find_driver = policy_scope(driver_class).kept.includes(*driver_includes).find(params[:id])

  def filtered(scope)
    scope = scope.where(operator_id: params[:operator_id]) if params[:operator_id].present? && driver_class == OperatorDriver
    return scope if params[:q].blank?

    like = "%#{driver_class.sanitize_sql_like(params[:q].to_s.strip)}%"
    digits = params[:q].to_s.gsub(/\D/, "")
    scope.where("#{driver_class.table_name}.name ILIKE :like#{' OR phone LIKE :digits' if digits.length >= 3}", like:, digits: "%#{digits}%")
  end

  def count_tabs(scope) = InvitedDriver::STATUSES.index_with(0).merge(scope.group(:status).count)
end
