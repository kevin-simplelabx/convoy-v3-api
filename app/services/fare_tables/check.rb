# The Bus Fares wizard's checks, step by step as in Convoy OS (fareCheck / payCheck / busCheck): the first problem as a
# sentence with the wizard step it belongs to (HTML step index: 0 Who Pays, 1 Billing, 2 Fares or Bus Rates,
# 3 Services, 4 CCA / ASA), or nil. f = the fare table as sent and cleaned (FareTables::Form), periods = its bills.
module FareTables
  class Check
    STEPS = [ "Who Pays", "Billing", "Fares", "Services", "CCA / ASA" ].freeze

    def self.problem(f, periods) = new(f, periods).problem

    def initialize(f, periods)
      @f = f
      @p = periods
    end

    # { message:, step:, step_name: } or nil.
    def problem
      steps.each_with_index do |check, i|
        message = check.call or next
        return { message:, step: i, step_name: i == 2 && @f[:payer] == "bus" ? "Bus Rates" : STEPS[i] }
      end
      nil
    end

    private

    def steps
      return [ -> { who_pays }, -> { no_periods if @p.empty? }, -> { per_bus } ] if @f[:payer] == "bus"

      [ -> { who_pays }, -> { billing }, -> { tiers || sizes || surcharges }, -> { services }, -> { cca } ]
    end

    def n?(x) = x.present? && x.to_s.match?(/\A\d+(\.\d+)?\z/)
    def trip = @f[:trip] || "both"
    def zones? = @f[:basis] == "zone"
    def unit = zones? ? "zone" : "tier"
    def no_periods = @f[:cycle] == "month" ? "Pick at least one billing month" : "The calendar has no terms"

    def who_pays
      return if (@f[:payer] || "parents") == "parents"

      b = @f[:bill_to] || {}
      return "Enter who the school bill goes to" if b[:name].to_s.strip.empty?

      "Enter a billing email for the school" unless b[:email].to_s.strip.match?(/\A\S+@\S+\.\S+\z/)
    end

    def per_bus
      rates = Array(@f[:bus_rates]).select { it[:rate].present? }
      return "Enter a rate for at least one bus size" if rates.empty?

      rates.each { |r| return "#{label(r[:bus_type])}: enter a rate above 0" unless r[:rate].to_d.positive? }
      return unless @f[:bus_count] == "booked"

      rates.each do |r|
        v = r[:booked_runs]
        return "#{label(r[:bus_type])}: runs booked must be a whole number" if v.present? && !v.to_s.match?(/\A\d+\z/)
      end
      "Enter how many runs the school booked" unless rates.any? { it[:booked_runs].to_i.positive? }
    end

    def billing
      return no_periods if @p.empty?
      if %w[prorated billpro].include?(@f[:distribution]) && @p.none? { it[:school_days].positive? }
        return "No school days found to prorate by. Check the calendar"
      end
      return unless trip == "both" && one_way[:type] != "custom"
      return "Enter the 1-way fare #{one_way[:type] == 'pct' ? 'percentage' : 'amount'}" unless n?(one_way[:value])

      "The 1-way percentage cannot be more than 100" if one_way[:type] == "pct" && one_way[:value].to_d > 100
    end

    def one_way = @f[:one_way] || {}
    def list = Array(@f[:tiers])

    def tier_label(i)
      t = list[i]
      return (t[:name].to_s.strip.presence || "Zone #{i + 1}") if zones?
      return (i.zero? ? "Any distance" : "Above #{list[i - 1][:max_km] || '?'} km") if i == list.size - 1

      "#{i.zero? ? '0' : (list[i - 1][:max_km] || '?')} to #{t[:max_km] || '?'} km"
    end

    def tiers
      return "Add at least one #{unit}" if list.empty?

      list.each_with_index do |t, i|
        lb = tier_label(i)
        if zones?
          return "Zone #{i + 1} needs a name" if t[:name].to_s.strip.empty?
          return "#{lb}: add postal sectors or draw the area" if Array(t[:sectors]).empty? && !Form.area?(t)
        elsif i < list.size - 1
          return "Tier #{i + 1} needs an upper distance" unless n?(t[:max_km]) && t[:max_km].to_d.positive?
          return "Tier #{i + 1} must end further out than tier #{i}" if i.positive? && t[:max_km].to_d <= list[i - 1][:max_km].to_d
        end
        problem = fares(t, lb) and return problem
        Array(t[:sizes]).each_with_index do |z, k|
          problem = fares(z, "#{lb}, size column #{k + 2}") and return problem
        end
      end
      nil
    end

    def fares(t, lb)
      word = { "one" => "1-way fare", "ampm" => "AM fare" }.fetch(trip, "2-way fare")
      if @f[:distribution] == "custom"
        return "#{lb}: enter every #{trip == 'ampm' ? 'AM ' : ''}bill amount" if @p.each_index.any? { !n?(Array(t[:period_fares])[it]) }
        return "#{lb}: enter every PM bill amount" if trip == "ampm" && @p.each_index.any? { !n?(Array(t[:period_pm_fares])[it]) }
      else
        return "#{lb}: enter the #{word}" unless n?(t[:fare])
        return "#{lb}: enter the PM fare" if trip == "ampm" && !n?(t[:pm_fare])
      end
      "#{lb}: enter the 1-way fare" if trip == "both" && one_way[:type] == "custom" && !n?(t[:one_way_fare])
    end

    def sizes
      return unless @f[:by_size]

      cols = Array(@f[:size_columns])
      return "Bus size pricing needs at least 2 size columns" if cols.size < 2

      cols[0...-1].each_with_index do |c, i|
        return "Enter the seat limit of size column #{i + 1}" unless c[:max_seats].to_i.positive?
        return "Size column #{i + 1} must have a higher seat limit than the one before" if i.positive? && c[:max_seats].to_i <= cols[i - 1][:max_seats].to_i
      end
      nil
    end

    def surcharges
      Array(@f[:surcharges]).each do |x|
        return "Every location surcharge needs a name" if x[:name].to_s.strip.empty?
        return "#{x[:name]}: add postal sectors or draw the area" if Array(x[:sectors]).empty? && !Form.area?(x)
        return "#{x[:name]}: enter the surcharge amount" unless n?(x[:amount])
        return "#{x[:name]}: enter the 1-way value" if (x[:one_way_kind] || "same") != "same" && !n?(x[:one_way_value])
      end
      nil
    end

    def services
      { small: "Small Bus", express: "Express" }.each do |k, name|
        s = @f[k] || {}
        next unless s[:on]

        if s[:type] == "custom"
          return "#{name}: enter a fare for every #{unit}" if list.any? { !n?(it[:"#{k}_fare"]) }
        elsif !n?(s[:value])
          return "#{name}: enter the extra #{s[:type] == 'pct' ? 'percentage' : 'amount'}"
        end
      end
      nil
    end

    def cca
      c = @f[:cca] || {}
      return unless c[:on]

      missing = c[:price] == "tier" ? list.any? { !n?(it[:cca_fare]) } : !n?(c[:fixed])
      return "CCA / ASA: enter #{c[:price] == 'tier' ? "a fare for every #{unit}" : 'the fare'}" if missing

      { non: "non-bus riders", am: "AM-only riders", pm: "PM-only riders" }.each do |k, who|
        r = (c[:riders] || {})[k] || {}
        return "CCA / ASA: enter the amount for #{who}" if r[:on] && !n?(r[:amount])
      end
      nil
    end

    def label(type) = SchoolBus::BUS_TYPES.dig(type, :label) || type
  end
end
