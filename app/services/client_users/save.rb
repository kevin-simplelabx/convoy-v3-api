# Client Users card: Add User (name, title, email, role, site access) and the Edit dialog (title, role, sites; the name
# and email stay). The person gets one portal account per email (they set the password at first sign-in).
# Rules (prototype): an email is not a Convoy OS user of the company; a site role picks at least one site when the
# client has sites; organisation-wide roles cover every site; every client keeps a Super Admin.
module ClientUsers
  class Save < ApplicationService
    def initialize(client:, params:, actor:, user: nil)
      @client = client
      @params = params
      @actor = actor
      @user = user || client.users.new(company_id: client.company_id, created_by: actor)
    end

    def call
      ClientUser.transaction do
        assign
        @user.save!
        save_sites
        keep_a_super_admin!
      end
      @user
    end

    private

    def assign
      if @user.new_record?
        @user.assign_attributes(@params.slice(:name, :email))
        check_email!
        @user.portal_account = PortalAccount.for_email!(@user.email, name: @user.name) if @user.email.match?(URI::MailTo::EMAIL_REGEXP)
      end
      @user.assign_attributes(@params.slice(:title, :role))
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
    end

    # Organisation-wide roles: no sites. Site roles: site_ids, or the sites they had.
    def site_ids
      return [] if @user.wide?
      return Array(@params[:site_ids]).compact_blank.map(&:to_i).uniq if @params.key?(:site_ids)

      @user.user_sites.pluck(:client_site_id)
    end

    def keep_a_super_admin!
      return if @user.previously_new_record? || @client.users.kept.super.exists?

      raise Error, "Keep at least one Super Admin for #{@client.name}"
    end
  end
end
