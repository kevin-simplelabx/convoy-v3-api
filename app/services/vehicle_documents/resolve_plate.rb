# The admin picks the right plate when the log card and the vehicle differ: use the card's or keep the vehicle's.
module VehicleDocuments
  class ResolvePlate < ApplicationService
    def initialize(card:, use:)
      @card = card
      @use = use.to_s
    end

    def call
      raise Error, "Pick card or vehicle" unless %w[card vehicle].include?(@use)

      VehicleLogCard.transaction do
        @card.update!(plate_conflict: false)
        @card.vehicle.update!(plate: @card.plate_on_card) if @use == "card"
      end
      @card
    end
  end
end
