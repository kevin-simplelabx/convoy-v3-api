# Upload a log card (or attach the file of a log card read): it becomes the current card, the old one moves to
# Past Log Cards, empty vehicle fields are filled from what Claude read, and a different plate is flagged.
module VehicleDocuments
  class AttachLogCard < ApplicationService
    include SourceFile

    Result = Data.define(:card, :filled)

    def initialize(vehicle:, user:, file: nil, document_read: nil)
      @vehicle = vehicle
      @user = user
      @file = file
      @read = document_read
    end

    def call
      file, values = source_file(@file, @read, "log_card")
      values ||= {}

      VehicleLogCard.transaction do
        @vehicle.log_cards.current.update_all(current: false)
        filled = fill_empty(@vehicle, values, Ai::Readers::LogCard::FIELDS)
        @vehicle.save!

        card = @vehicle.log_cards.create!(file:, uploaded_by: @user, plate_on_card: values[:plate],
                                          plate_conflict: values[:plate].present? && values[:plate] != @vehicle.plate)
        @vehicle.reload
        Result.new(card, filled)
      end
    end
  end
end
