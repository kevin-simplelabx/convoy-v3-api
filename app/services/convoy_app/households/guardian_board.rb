# Authorised Guardians screen: for each child, every adult of the Family and whether they can receive the child at drop-off.
# state: always (Mother / Father, locked) | on | off | pending (invite not accepted) | needs_photo.
module ConvoyApp
  module Households
    class GuardianBoard < ApplicationService
      def initialize(household:, dependant_id: nil)
        @household = household
        @dependant_id = dependant_id
      end

      def call
        members = @household.members.select { it.active? || it.invited? }.map(&:decorate)
        children = @household.dependants.select { @dependant_id.nil? || it.id == @dependant_id }
        allowed = DependantGuardian.where(dependant_id: children.map(&:id)).pluck(:dependant_id, :household_member_id).to_set
        children.map { child_json(it, members, allowed) }
      end

      private

      def child_json(child, members, allowed)
        rows = members.map { adult_json(it, allowed.include?([ child.id, it.id ])) }
        { id: child.id, name: child.name, first_name: child.first_name, can_receive: rows.count { it[:can_receive] }, of: rows.size, adults: rows }
      end

      def adult_json(member, on)
        state = if !member.active? then "pending"
        elsif member.parent? then "always"
        elsif on && member.photo.present? then "on"
        elsif on || member.photo.present? then (on ? "on" : "off")
        else "needs_photo"
        end
        { member_id: member.id, name: member.name, photo: member.photo_info, relationship: member.relationship, status: member.status,
          state:, allowed: on, can_receive: %w[always on].include?(state) }
      end
    end
  end
end
