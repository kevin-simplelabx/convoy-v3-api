# Create Your Account (first name, last name, Show My Name As, Terms) and later changes to the name, photo and the
# notification switches. Terms must be accepted once, on Create Your Account.
module ConvoyApp
  class SaveProfile < ApplicationService
    BOOL = ActiveModel::Type::Boolean.new

    def initialize(account:, params:)
      @account = account
      @params = params.to_h.symbolize_keys
    end

    def call
      attrs = @params.slice(:first_name, :last_name, :name_order, :photo, :remove_photo)
      %i[notify_push notify_sms notify_email].each { |k| attrs[k] = BOOL.cast(@params[k]) if @params.key?(k) }
      attrs[:terms_accepted_at] = Time.current if BOOL.cast(@params[:accept_terms]) && @account.terms_accepted_at.nil?
      @account.assign_attributes(attrs)
      check!
      @account.save!
      @account
    end

    private

    def check!
      if @account.first_name.blank? || @account.last_name.blank?
        missing = %i[first_name last_name].select { @account.public_send(it).blank? }
        raise Error.new("Enter your first and last name", details: missing.to_h { [ it, [ "can't be blank" ] ] })
      end
      return if @account.terms_accepted_at

      raise Error.new("Agree to the Terms of Use and Privacy Notice to continue", details: { accept_terms: [ "must be accepted" ] })
    end
  end
end
