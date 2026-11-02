# Puts a whole rate card from the Rate Cards edit page onto a card in memory: settings, vehicle types (columns), periods
# with time ranges and rates, distance bands, stop and disposal amounts. Children are rebuilt from the params each time.
# #errors lists the rules the page checks before saving (first one is shown); Save persists, Check only reads.
module RateCards
  class Form
    SCALARS = %i[name description wait_free_minutes wait_fee wait_block_minutes meet_and_greet meet_and_greet_fee
                 distance_pricing stop_fees disposal_mode disposal_free_km].freeze
    PERMIT = [ *SCALARS, { vehicle_type_ids: [] },
               { periods: [ :name, :override, { days: [] }, { ranges: %i[starts_at ends_at] }, { rates: %i[vehicle_type_id trip_rate hourly_rate] } ] },
               { distance_bands: [ :up_to_km, :per_km, { amounts: %i[vehicle_type_id amount] } ] },
               { stop_fee_amounts: %i[vehicle_type_id amount] }, { disposal_km_amounts: %i[vehicle_type_id amount] } ].freeze

    attr_reader :card, :errors

    def initialize(card, params)
      @card = card
      @params = params.to_h.deep_symbolize_keys
      @errors = []
    end

    # Builds the card; the existing children must be gone (Save deletes them first).
    def build
      @card.assign_attributes(@params.slice(*SCALARS))
      @card.name = @card.name.to_s.strip
      @types = types
      @types.each_with_index { |t, i| @card.card_vehicle_types.build(vehicle_type: t, position: i) }
      build_periods
      build_bands
      build_amounts("stop_fee", @params[:stop_fee_amounts])
      build_amounts("disposal_km", @params[:disposal_km_amounts])
      check
      self
    end

    def valid? = errors.empty?

    private

    def types
      ids = Array(@params[:vehicle_type_ids]).map(&:to_i).uniq
      found = VehicleType.enabled_for(ActsAsTenant.current_tenant).where(id: ids).index_by(&:id)
      @errors << "Pick vehicle types the company offers" if found.size < ids.size
      ids.filter_map { |id| found[id] }
    end

    def build_periods
      Array(@params[:periods]).each_with_index do |p, i|
        period = @card.periods.build(name: p[:name].to_s.strip, days: Array(p[:days]).uniq, override: ActiveModel::Type::Boolean.new.cast(p[:override]) || false, position: i)
        Array(p[:ranges]).each { |r| period.ranges.build(starts_at: r[:starts_at], ends_at: r[:ends_at]) }
        given = Array(p[:rates]).index_by { |r| r[:vehicle_type_id].to_i }
        @types.each do |t|
          r = given[t.id] || {}
          period.rates.build(vehicle_type: t, trip_rate: r[:trip_rate].presence || 0, hourly_rate: r[:hourly_rate].presence || 0)
        end
      end
    end

    def build_bands
      Array(@params[:distance_bands]).each_with_index do |b, i|
        band = @card.distance_bands.build(position: i, up_to_km: b[:up_to_km].presence, per_km: ActiveModel::Type::Boolean.new.cast(b[:per_km]) || false)
        build_amounts("distance_band", b[:amounts], band:)
      end
    end

    # One amount per vehicle type of the card (0 when not given).
    def build_amounts(kind, list, band: nil)
      given = Array(list).index_by { |a| a[:vehicle_type_id].to_i }
      @types.each do |t|
        @card.amounts.build(kind:, vehicle_type: t, rate_card_distance_band: band, amount: given.dig(t.id, :amount).presence || 0)
      end
    end

    def check
      @errors << "Enter the card name" if @card.name.blank?
      @errors << "Another card has this name" if @card.name.present? && name_taken?
      @errors << "Keep at least one vehicle type" if @types.empty?
      periods = @card.periods
      @errors << "Add at least one period" if periods.empty?
      @errors << "Name every period" if periods.any? { |p| p.name.blank? }
      @errors << "Every period needs at least one day" if periods.any? { |p| p.days.empty? }
      @errors << "Every period needs at least one time range" if periods.any? { |p| p.ranges.empty? }
      ranges = periods.flat_map(&:ranges)
      @errors << "Enter every time as HH:MM" if ranges.any? { |r| [ r.starts_at, r.ends_at ].any? { |m| m.nil? || m > 1439 } }
      @errors << "A time range can't start and end at the same time" if ranges.any? { |r| r.starts_at && r.starts_at == r.ends_at }
      check_bands
    end

    def name_taken?
      RateCard.where.not(id: @card.id).exists?([ "LOWER(name) = ?", @card.name.downcase ])
    end

    # Bands go up in km; the last has no upper limit and is the only one that may charge per km.
    def check_bands
      bands = @card.distance_bands
      return @errors << "Add the distance bands" if @card.distance_pricing? && bands.size < 2
      return if bands.empty?

      limits = bands[0...-1].map(&:up_to_km)
      @errors << "Enter the km of every band but the last" if limits.any?(&:nil?)
      @errors << "Distance bands must go up in km" if limits.compact.each_cons(2).any? { |a, b| b <= a } || limits.compact.any? { |x| x <= 0 }
      @errors << "The last distance band has no upper limit" unless bands.last.up_to_km.nil?
      @errors << "Only the last distance band can charge per km" if bands[0...-1].any?(&:per_km)
    end
  end
end
