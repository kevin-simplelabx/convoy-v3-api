# Add or change a client user: from Convoy OS (Managed Clients › Client Users: name, title, email, role, sites) or from
# the Client Portal (Settings › Users: name, email, role, sites, team, manager). The person gets one portal account per
# email (they set the password at first sign-in).
# Rules (prototype): an email is not a Convoy OS user of the company; a site role picks at least one site when the
# client has sites; organisation-wide roles cover every site; every client keeps a Super Admin. In the portal the
# actor (a client user) also gives only roles they may give, only their own sites, and changes only people they manage.
module ClientUsers
  class Save < ApplicationService
    def initialize(client:, params:, actor:, user: nil)
      @client = client
      @params = params.to_h.symbolize_keys
      @actor = actor
      @user = user || client.users.new(company_id: client.company_id, **creator)
    end

    def call
      ClientUser.transaction do
        @client.lock!
        check_portal_actor!
        assign
        @user.save!
        save_sites
        check_portal_sites!
        keep_a_super_admin!
      end
      @user
    end

    private

    def portal? = @actor.is_a?(ClientUser)
    def creator = portal? ? { created_by_client_user: @actor } : { created_by: @actor }

    def assign
      if @user.new_record?
        @user.assign_attributes(@params.slice(:name, :email))
        check_email!
        @user.portal_account = PortalAccount.for_email!(@user.email, name: @user.name) if @user.email.match?(URI::MailTo::EMAIL_REGEXP)
      end
      @user.assign_attributes(@params.slice(:title, :role))
      @user.client_team_id = @params[:team_id].presence if @params.key?(:team_id)
      @user.manager_id = @params[:manager_id].presence if @params.key?(:manager_id)
    end

    def check_email!
      return if @user.email.blank?
      return unless User.kept.exists?(company_id: @client.company_id, email: @user.email)

      raise Error, "#{@user.email} belongs to a Convoy OS user of your company"
    end

    def save_sites
      ids = site_ids
      found = @client.sites.where(id: ids).pluck(:id)
      raise Error, "Some sites are not sites of #{@client.name}" if found.size != ids.size
      raise Error, "Pick at least one site for a #{@user.role_label}" if !@user.wide? && found.empty? && @client.sites.exists?

      @user.user_sites.where.not(client_site_id: found).delete_all
      (found - @user.user_sites.pluck(:client_site_id)).each { |id| @user.user_sites.create!(client_site_id: id) }
      @user.forget_sites!
    end

    # Organisation-wide roles: no sites. Site roles: site_ids, or the sites they had.
    def site_ids
      return [] if @user.wide?
      return Array(@params[:site_ids]).compact_blank.map(&:to_i).uniq if @params.key?(:site_ids)

      @user.user_sites.pluck(:client_site_id)
    end

    def check_portal_actor!
      return unless portal?
      raise Error, "You cannot add people" if @user.new_record? && !@actor.can?(:users)
      raise Error, "You cannot change #{@user.name}" if @user.persisted? && !@actor.manages?(@user, :edit)

      role = @params[:role].presence || @user.role
      raise Error, "You cannot give this role" unless @actor.roles_to_give.include?(role)
    end

    def check_portal_sites!
      return if !portal? || @actor.all_sites? || @user.wide?
      return if (@user.picked_site_ids - @actor.picked_site_ids).empty?

      raise Error, "You can only give your own sites"
    end

    def keep_a_super_admin!
      return if @user.previously_new_record? || @client.users.kept.super.exists?

      raise Error, "Keep at least one Super Admin for #{@client.name}"
    end
  end
end
