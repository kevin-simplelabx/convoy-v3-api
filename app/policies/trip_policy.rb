# Trips: every company user may create, edit and delete them (the Scheduler has no separate permission).
class TripPolicy < ApplicationPolicy
  FIELDS = %i[kind client_id client_site_id title label starts_on start_time end_time hours end_mode ends_on occurrence_count
              skip_public_holidays calendar_id pax luggage_on luggage_cabin luggage_medium luggage_large luggage_extra_large
              luggage_oversized vehicles_count requestor_name requestor_email requestor_phone guest_is_requestor guest_name
              guest_phone notes business_unit project booking_ref airport_direction flight_number flight_time terminal
              wait_minutes meet_and_greet signboard_name meet_and_greet_fee price price_per price_set price_basis hourly_rate
              trip_value trip_value_mode trip_value_rounding operator_cost operator_cancel_rule subcontracted
              client_end_customer_id service_for contractor_contact_name contractor_contact_phone require_contractor_app
              shuttle_return shuttle_separate_return price_by trip_value_per trip_value_return color approved_riders_only
              seat_reservation head_count route_tags no_fixed_bus session paid_months_mode unpaid_month_share
              charge_no_school_days lock_version].freeze
  PHOTOS = [ :id, :photo, :position, :_destroy ].freeze
  STUDENT = %i[id position name class_name parent_name phone phone2 note _destroy].freeze
  STOP = [ :id, :direction, :position, :name, :return_name, :use, :address, :lat, :lng, :driver_note, :street_view_url,
           :client_site_id, :scheduled_time, :_destroy, { photos_attributes: PHOTOS, students_attributes: STUDENT } ].freeze
  RUN_SLOT = %i[id slot_no vehicle_id unassigned group_key _destroy].freeze
  # times: one per stop in travel order of the run's direction ("07:30", "" where it skips the stop)
  RUN = [ :id, :direction, :position, :trip_value, :standby_needed, :_destroy, { times: [], slots_attributes: RUN_SLOT } ].freeze
  PRICE_CELL = %i[row col amount].freeze
  VIA = %i[id direction from_position position lat lng _destroy].freeze
  REQUIREMENT = %i[id vehicle_type_id count _destroy].freeze
  SLOT = %i[id slot_no vehicle_id price _destroy].freeze
  STANDBY = [ :id, :location, :minutes, :lat, :lng, :address, :note, :street_view_url, :_destroy, { photos_attributes: PHOTOS } ].freeze
  # permit syntax (not expect): nested lists may come as JSON arrays or as multipart hashes keyed "0", "1"...
  NESTED = { stops_attributes: STOP, route_vias_attributes: VIA, vehicle_requirements_attributes: REQUIREMENT,
             vehicle_slots_attributes: SLOT, standby_attributes: STANDBY, attachments_attributes: %i[id file _destroy],
             runs_attributes: RUN, price_table: PRICE_CELL, route_tags: [], unpaid_months: [] }.freeze # route_tags: a list, or text with commas
  RETURN = [ :start_time, :end_time, :return_billing, { stops_attributes: STOP, route_vias_attributes: VIA,
                                                        vehicle_slots_attributes: SLOT, standby_attributes: STANDBY } ].freeze

  def permitted_attributes = [ *FIELDS, { days: [] }, NESTED ]
end
