# Make a receipt void (the only School Finance document that can be): why, by whom; its payments are void too, so the
# bills it paid are owed again.
module SchoolBills
  class VoidReceipt < ApplicationService
    def initialize(receipt, reason:, user:, now: Time.current)
      @receipt = receipt
      @reason = reason.to_s.strip
      @user = user
      @now = now
    end

    def call
      raise Error, "Only a receipt can be made void" unless @receipt.receipt?
      raise Error, "#{@receipt.number} is already void" if @receipt.voided?
      raise Error, "Enter why the receipt is void" if @reason.empty?

      ApplicationRecord.transaction do
        @receipt.update!(voided_at: @now, void_reason: @reason, voided_by: @user)
        @receipt.payments.update_all(voided_at: @now, updated_at: @now)
      end
      @receipt
    end
  end
end
