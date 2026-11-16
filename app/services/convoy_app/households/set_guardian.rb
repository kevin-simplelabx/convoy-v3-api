# Authorised Guardians: switch one adult on or off to receive one child at drop-off. A Mother or Father always can (locked);
# anyone else needs to be in the Family (accepted) and to have a photo.
module ConvoyApp
  module Households
    class SetGuardian < ApplicationService
      BOOL = ActiveModel::Type::Boolean.new

      def initialize(dependant:, member:, allowed:)
        @dependant = dependant
        @member = member
        @allowed = BOOL.cast(allowed)
      end

      def call
        raise Error.new("Mother and Father can always receive #{@dependant.first_name}", code: "always") if @member.parent?
        raise Error.new("Can be switched on once #{@member.first_name} accepts the invite", code: "not_accepted") if @allowed && !@member.active?
        raise Error.new("#{@member.first_name} needs a photo first", code: "needs_photo") if @allowed && @member.photo.blank?

        row = DependantGuardian.find_or_initialize_by(dependant: @dependant, household_member: @member)
        @allowed ? row.save! : row.destroy!
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end
end
