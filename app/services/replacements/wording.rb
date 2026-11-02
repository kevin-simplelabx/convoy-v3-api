# Sentences about a replacement (port of schRpTxt, schRpPay and the notify message of the Replace form).
module Replacements
  class Wording
    def initialize(rep)
      @r = rep
      @c = rep.company
    end

    def when_text
      return "#{trip_title} on #{d(@r.run_date)}" if @r.for_run?

      "Trips on #{plate(@r.original_vehicle)} from #{d(@r.starts_on)}#{@r.ends_on == @r.starts_on ? '' : " to #{d(@r.ends_on)}"}"
    end

    def summary
      span = @r.for_run? ? "This trip on #{d(@r.run_date)}" : "#{d(@r.starts_on)}#{@r.ends_on == @r.starts_on ? '' : " to #{d(@r.ends_on)}"}"
      tail = [ (@r.eta.present? && @r.kind != "drv") ? "ETA #{@r.eta}" : nil, @r.reason.presence ].compact.map { |x| " #{x}." }.join
      lead = case @r.kind
      when "drv" then "#{new_driver}#{new_phone ? " (#{new_phone})" : ''} drives #{plate(@r.original_vehicle)}"
      when "veh" then "#{old_driver} drives #{plate(@r.vehicle)} instead of #{plate(@r.original_vehicle)}"
      when "crew" then "#{plate(@r.vehicle)} with #{new_driver} takes over from #{plate(@r.original_vehicle)}"
      else "#{plate(@r.vehicle)} with #{new_driver} took over from #{plate(@r.original_vehicle)} at #{@r.handover_stop}, #{@c.format_time(@r.handover_time)}"
      end
      "#{lead}. #{span}.#{tail}"
    end

    def pay_text
      case @r.kind
      when "drv" then "Trip value goes to #{new_driver}, the replacement driver"
      when "veh" then "Trip value goes to #{old_driver}, the original driver"
      when "crew" then "Trip value goes to the new crew, #{new_driver}"
      else
        case @r.pay_split
        when "original" then "Trip value goes to the original crew, #{old_driver}"
        when "new" then "Trip value goes to the new crew, #{new_driver}"
        when "both" then "Both crews get the full trip value: #{old_driver} and #{new_driver}"
        else "#{old_driver} gets #{@r.original_share}% and #{new_driver} gets #{100 - @r.original_share.to_i}% of the trip value"
        end
      end
    end

    # What guests or parents are told.
    def message
      body = case @r.kind
      when "drv" then "Your driver is #{new_driver}#{new_phone ? ", #{new_phone}" : ''}. The bus is still #{plate(@r.original_vehicle)}"
      when "veh" then "Your bus is now #{plate(@r.vehicle)}, driven by #{old_driver}"
      when "crew" then "Your bus is now #{plate(@r.vehicle)}, driven by #{new_driver}#{new_phone ? ", #{new_phone}" : ''}"
      else "Riders on board move to #{plate(@r.vehicle)}, driven by #{new_driver}#{new_phone ? ", #{new_phone}" : ''}, at #{@r.handover_stop}"
      end
      "Convoy update: #{when_text}. #{body}#{@r.eta.present? ? ". Updated ETA #{@r.eta}" : ''}. Sorry for the change."
    end

    private

    def d(date) = @c.format_date(date)
    def plate(v) = v&.plate || "the bus"
    def trip_title = @r.trip&.title || @r.school_route&.title || "This trip"

    def new_driver
      @r.new_driver_label.presence || (@r.vehicle && Occurrences::Fleet.new.driver_on(@r.vehicle_id, @r.starts_on)&.name) || "its regular driver"
    end

    def new_phone = @r.driver&.phone || @r.operator_driver&.phone || @r.driver_phone.presence
    def old_driver = Occurrences::Fleet.new.driver_on(@r.original_vehicle_id, @r.starts_on)&.name || "the regular driver"
  end
end
