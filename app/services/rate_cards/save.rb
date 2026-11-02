# Create or edit a rate card from the edit page (the whole card each time; children are replaced).
# The first active card becomes the default. Returns the card; the warnings come from RateCards::Check.
module RateCards
  class Save < ApplicationService
    def initialize(card:, params:, lock_version: nil)
      @card = card
      @params = params
      @lock_version = lock_version
    end

    def call
      RateCard.transaction do
        if @card.persisted?
          # Children are replaced, so check the lock first and always write the card (bumps lock_version).
          raise ActiveRecord::StaleObjectError.new(@card, "update") if !@lock_version.nil? && @lock_version.to_i != @card.lock_version

          clear_children
          @card.updated_at = Time.current
        end
        form = Form.new(@card, @params).build
        raise Error, form.errors.first unless form.valid?

        @card.default_card = true if @card.new_record? && !RateCard.active.exists?(default_card: true)
        @card.save!
        @card
      end
    end

    private

    def clear_children
      @card.amounts.delete_all
      @card.distance_bands.delete_all
      RateCardRange.where(period: @card.periods).delete_all
      RateCardRate.where(period: @card.periods).delete_all
      @card.periods.delete_all
      @card.card_vehicle_types.delete_all
      @card.association(:periods).reset
      @card.association(:distance_bands).reset
      @card.association(:amounts).reset
      @card.association(:card_vehicle_types).reset
    end
  end
end
