# Convoy App › CCA Bus, Same Days Every Week for one child: the weekdays picked for next week each week. They only pre-pick
# the days; the parent still pays to confirm. days: [] turns it off. Only the school's CCA bus days can be saved.
module ConvoyApp
  module Cca
    class SameDays < ApplicationService
      def initialize(member:, school_id:, dependant_id:, days:)
        @household = member.household
        @school_id = school_id
        @dependant_id = dependant_id
        @days = Array(days).map(&:to_i).uniq.sort
      end

      def call
        offer = Cca.offer!(@household, @school_id)
        kid = offer.kids.find { it.dependant.id == @dependant_id.to_i } or raise ActiveRecord::RecordNotFound
        Parents.within(offer.company) do
          allowed = offer.setting.days
          raise Error, "The CCA bus runs on #{Cca.days_text(allowed)}" unless (@days - allowed).empty?

          row = CcaStandingDay.find_by(family: offer.family, school_rider: kid.rider)
          if @days.empty?
            row&.destroy!
          else
            (row || CcaStandingDay.new(family: offer.family, school_rider: kid.rider, school: offer.school)).update!(days: @days)
          end
          first = kid.dependant.first_name
          { dependant_id: kid.dependant.id, on: @days.any?, days: @days,
            text: @days.any? ? "#{Cca.days_text(@days)} are picked for #{first} each week. Still pay by Saturday 23:59 to confirm" : "Pick the same days for #{first} each week" }
        end
      end
    end
  end
end
