# Finance > Finance Settings: Save / Save & Lock (rules of the prototype). approvers: the whole list
# [{ user_id, can_prepare, can_approve }].
module Finance
  class SaveSettings < ApplicationService
    FIELDS = %i[gst_on gst_rate gst_mode gst_reg_no approval brand_name brand_uen brand_address brand_phone brand_email brand_note
                bank_id account_number account_name paynow payment_note] + FinanceSetting::DOC_TYPES.keys.map { |t| :"prefix_#{t}" }

    def initialize(settings:, params:, user:, lock: false)
      @s = settings
      @params = params
      @user = user
      @lock = lock
    end

    def call
      raise Error, "Finance Settings are locked. Unlock to change them" if @s.locked?

      FinanceSetting.transaction do
        @s.assign_attributes(@params.slice(*FIELDS))
        rows = approver_rows
        check!(rows)
        @s.save!
        save_approvers(rows) if rows
        @s.update!(locked_at: Time.current, locked_by: @user) if @lock
      end
      @s
    end

    private

    def approver_rows
      return nil unless @params.key?(:approvers)

      Array(@params[:approvers]).map { |r| r.to_h.symbolize_keys }.map do |r|
        { user_id: r[:user_id].to_i, can_prepare: bool(r[:can_prepare], true), can_approve: bool(r[:can_approve], false) }
      end.uniq { |r| r[:user_id] }
    end

    def check!(rows)
      raise Error, "Enter a GST rate between 0 and 100" if @s.gst_on? && !(@s.gst_rate.to_d.positive? && @s.gst_rate < 100)

      prefixes = FinanceSetting::DOC_TYPES.keys.map { |t| @s.prefix(t) }
      raise Error, "Every document type needs a prefix" if prefixes.any?(&:blank?)
      raise Error, "Each document type needs its own prefix" if prefixes.uniq.size < prefixes.size
      raise Error, "Enter the account number" if @s.bank_id && @s.account_number.blank?

      rows ||= @s.approvers.map { |a| { user_id: a.user_id, can_prepare: a.can_prepare, can_approve: a.can_approve } }
      users = User.kept.active.where(company_id: @s.company_id)
      raise Error, "Some approvers are not users of this company" if users.where(id: rows.pluck(:user_id)).count != rows.size

      approvers = rows.select { |r| r[:can_approve] }
      raise Error, "Add at least one approver for operator pay runs" if approvers.empty?
      return unless @s.approval_maker?

      raise Error, "Maker-checker needs at least two active users. Add another user first" if users.count < 2
      return if approvers.size >= 2 || rows.any? { |r| r[:can_prepare] && !r[:can_approve] }

      raise Error, "Maker-checker needs at least two people: add a second approver or a preparer"
    end

    def save_approvers(rows)
      FinanceApprover.where(company_id: @s.company_id).where.not(user_id: rows.pluck(:user_id)).destroy_all
      rows.each do |r|
        FinanceApprover.find_or_initialize_by(company_id: @s.company_id, user_id: r[:user_id]).update!(r.slice(:can_prepare, :can_approve))
      end
    end

    def bool(value, default) = value.nil? ? default : ActiveModel::Type::Boolean.new.cast(value)
  end
end
