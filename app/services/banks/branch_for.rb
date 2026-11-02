# The branch of a Singapore bank account, from the bank's branch_rule and the account number:
# { code:, name:, send: (account number as sent in payment files), note: } or { code: nil, error:, field: } when it
# can't be worked out (field: the form field to fix, with error_message as a model error on it). For rule "list" the branch is picked: pass branch_code (or the bank's only branch is used).
module Banks
  class BranchFor < ApplicationService
    def initialize(bank:, account_number:, branch_code: nil)
      @bank = bank
      @digits = account_number.to_s.gsub(/\D/, "")
      @picked = branch_code.to_s.gsub(/\D/, "").presence
    end

    def call
      return { code: "081", name: "All Branches", send: @digits } if @bank.branch_rule == "posb"
      return from_list if @bank.branch_rule == "list"
      return failed(@bank.rule_text, :account_number, "is too short") if @digits.length < 3

      case @bank.branch_rule
      when "pre3"
        return { code: "081", name: "POSB, 9-digit account", send: @digits, note: "9-digit DBS accounts are POSB accounts, so 081 is used" } if @digits.length == 9

        named(@digits[0, 3], @digits)
      when "pre3drop" then named(@digits[0, 3], @digits[3..])
      when "sc" then named("0#{@digits[0, 2]}", @digits)
      when "uob"
        row = @bank.branches.find { |b| b.account_prefix == @digits[0, 3] }
        row ? { code: row.code, name: row.name, send: @digits } : failed("No UOB branch matches the first 3 digits of this account number", :account_number, "matches no UOB branch (check the first 3 digits)")
      end
    end

    private

    def failed(error, field, error_message) = { code: nil, error:, field:, error_message: }

    def named(code, send) = { code:, name: @bank.branches.find { |b| b.code == code }&.name, send: }

    def from_list
      only = @bank.branches.one? ? @bank.branches.first : nil
      code = @picked || only&.code
      unless code&.match?(/\A\d{3}\z/)
        return @bank.branches.any? ? failed("Pick the branch", :branch_code, "must be picked") : failed("Enter the 3-digit branch code", :branch_code, "must be 3 digits")
      end

      named(code, @digits)
    end
  end
end
