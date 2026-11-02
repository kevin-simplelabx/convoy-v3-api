# Settings > Users > Add User / Edit (Save User). New users get a name, email and password; afterwards only their
# permissions, Super Admin and schools change here (name and email are set at creation; the Profile keeps the rest).
# A user with every permission, or a Super Admin, is an Admin and opens every school.
module Users
  class Save < ApplicationService
    include Guard

    def initialize(actor:, company:, params:, user: nil)
      @actor = actor
      @company = company
      @params = params
      @user = user || company.users.new(created_by: actor)
    end

    def call
      guard_owner!(@user) if @user.persisted?
      assign
      User.transaction do
        @user.save!
        save_schools
        keep_an_owner!(@company)
      end
      @user
    end

    private

    def assign
      @user.assign_attributes(@params.slice(:name, :email, :password).compact) if @user.new_record?
      owner = @params.key?(:owner) ? bool(@params[:owner]) : @user.owner?
      raise Error, "Only a Super Admin can make a Super Admin" if owner && !@user.owner? && !@actor.owner?

      perms = @params.key?(:permissions) ? Array(@params[:permissions]).map(&:to_s).uniq : @user.permissions
      full = owner || (User::PERMISSIONS - perms).empty?
      if @user.id == @actor.id && @actor.can?(:users) && !(full || perms.include?("users"))
        raise Error, "You can't remove your own Users permission"
      end

      @user.assign_attributes(owner:, role: full ? :admin : :member, permissions: full ? User::PERMISSIONS : perms)
    end

    # all_schools: true = every school, including new ones; otherwise only school_ids (may be none). Admins: always all.
    def save_schools
      if @user.admin? then ids = nil
      elsif @params.key?(:all_schools) || @params.key?(:school_ids)
        all = @params.key?(:all_schools) ? bool(@params[:all_schools]) : false
        ids = all ? nil : Array(@params[:school_ids]).compact_blank.map(&:to_i).uniq
      else return
      end

      found = ids ? School.where(company: @company, id: ids).pluck(:id) : []
      raise Error, "Some schools were not found" if ids && found.size != ids.size

      @user.update!(all_schools: ids.nil?) if @user.all_schools? != ids.nil?
      @user.user_schools.where.not(school_id: found).delete_all
      (found - @user.user_schools.pluck(:school_id)).each { |id| @user.user_schools.create!(school_id: id) }
    end

    def bool(value) = ActiveModel::Type::Boolean.new.cast(value) || false
  end
end
