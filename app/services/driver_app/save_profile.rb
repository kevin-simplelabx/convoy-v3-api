# Account › Personal Details and Complete My Profile: name, date of birth, nationality and residential status, NRIC / FIN,
# address and postal code, photo. Details verified with Singpass are locked; the NRIC / FIN can only be added once (it is
# then verified). The companies the driver works for get the new copy.
module DriverApp
  class SaveProfile < ApplicationService
    LABELS = { "name" => "Full Name", "date_of_birth" => "Date of Birth", "nationality" => "Nationality",
               "residential_status" => "Residential Status", "id_number" => "NRIC / FIN", "address" => "Residential Address",
               "postal_code" => "Postal Code" }.freeze

    def initialize(account:, params:)
      @account = account
      @params = params.to_h.stringify_keys
    end

    def call
      values = @params.slice(*DriverAccount::PROFILE_FIELDS)
      locked = values.keys.select { |k| @account.locked_fields.include?(k) && changes?(k, values[k]) }
      raise Error.new("#{locked.map { LABELS[it] }.to_sentence} #{locked.one? ? 'is' : 'are'} verified with Singpass and cannot be changed here",
                      details: locked.index_with { [ "is verified with Singpass" ] }) if locked.any?
      if values.key?("id_number") && @account.id_number.present? && changes?("id_number", values["id_number"])
        raise Error.new("Your NRIC / FIN is verified, so it cannot be changed here", details: { id_number: [ "cannot be changed" ] })
      end

      @account.assign_attributes(values)
      @account.photo = @params["photo"] if @params["photo"].present?
      @account.remove_photo! if ActiveModel::Type::Boolean.new.cast(@params["remove_photo"])
      @account.transaction do
        @account.save!
        ShareProfile.call(account: @account)
      end
      @account
    end

    private

    def changes?(key, value) = @account.class.new(key => value).public_send(key) != @account.public_send(key)
  end
end
