# Add a Child / edit one (Household › Children): name as on the birth certificate, date of birth, school (one Convoy runs
# buses for, or "Other" with the name typed), level next year, gender, student id, photo and medical conditions. Bus service is
# applied for separately.
module ConvoyApp
  module Households
    class SaveDependant < ApplicationService
      FIELDS = %i[name birth_date level gender student_id medical_note photo].freeze

      def initialize(household:, params:, dependant: nil)
        @household = household
        @dependant = dependant || household.dependants.build
        @params = params.to_h.symbolize_keys
      end

      def call
        attrs = @params.slice(*FIELDS)
        attrs[:remove_photo] = @params[:remove_photo] if @params.key?(:remove_photo)
        attrs[:medical_tags] = Array(@params[:medical_tags]).compact_blank.uniq if @params.key?(:medical_tags)
        @dependant.assign_attributes(attrs)
        set_school if @params.key?(:school_id) || @params.key?(:school_name)
        check!
        @dependant.save!
        @dependant
      end

      private

      # school_id of a school in the directory (its name is used), or school_name typed for "Other".
      def set_school
        if @params[:school_id].present?
          row = SchoolDirectory.find(@params[:school_id]) or raise Error.new("Choose the school", details: { school_id: [ "is not a school on Convoy" ] })
          @dependant.assign_attributes(school_id: row[:id], school_name: row[:name])
        else
          @dependant.assign_attributes(school_id: nil, school_name: @params[:school_name])
        end
      end

      def check!
        field, message = if @dependant.name.blank? then [ :name, "Enter the full name" ]
        elsif @dependant.birth_date.blank? then [ :birth_date, "Enter the date of birth" ]
        elsif @dependant.school_name.blank? then [ :school_id, "Choose the school" ]
        elsif @dependant.level.blank? then [ :level, "Choose the level" ]
        end
        raise Error.new(message, details: { field => [ message ] }) if field
      end
    end
  end
end
