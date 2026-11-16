# Change of Address with "Update the Family's residential address" on: once the company confirms the move (the request
# turns Active, straight away or after the parent agrees to the new fare), the Family's home becomes the typed address.
# Runs once per Family address (the same move sent for two children applies once). Called by BusRequests::ConfirmChange
# and BusRequests::Agree; a move the company declines never changes the home.
module ConvoyApp
  module Parents
    class MoveHome < ApplicationService
      FIELDS = %w[block street floor unit line2 postal lat lng].freeze

      def initialize(req)
        @req = req
      end

      def call
        return unless @req.kind == "adr" && @req.status == "Active" && @req.new_home.present?

        household = @req.household
        return unless household&.kept?

        attrs = @req.new_home.slice(*FIELDS)
        return if FIELDS.all? { household.public_send(it).to_s == attrs[it].to_s }

        household.update!(attrs)
        @req.log!("Family address changed to #{household.address}, S#{household.postal}", by: "Convoy")
        household
      end
    end
  end
end
