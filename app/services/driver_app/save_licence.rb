# Account › Driving Credentials: add, update or remove a licence (classes, number, dates, card photos). The companies the
# driver works for get the new list.
module DriverApp
  class SaveLicence < ApplicationService
    FIELDS = %w[kind name classes number issued_on expires_on].freeze

    def initialize(account:, params: {}, licence: nil, remove: false)
      @account = account
      @licence = licence || account.licences.build
      @params = params.to_h.stringify_keys
      @remove = remove
    end

    def call
      @account.transaction do
        if @remove
          @licence.destroy!
        else
          @licence.assign_attributes(@params.slice(*FIELDS))
          %w[card_front card_back].each do |mount|
            @licence.public_send(:"#{mount}=", @params[mount]) if @params[mount].present?
            @licence.public_send(:"remove_#{mount}!") if ActiveModel::Type::Boolean.new.cast(@params["remove_#{mount}"])
          end
          @licence.save!
        end
        ShareProfile.call(account: @account.reload)
      end
      @licence
    end
  end
end
