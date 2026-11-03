# Add a stop to a school (Add to School / Use Stop) or change the school's catchment of it: postal codes (6 digits;
# others are returned as invalid), drawn areas and points this school does not use. A stop with a catchment needs both
# a pick-up and a drop-off point. Returns the school stop, the invalid codes and the codes another of the school's stops
# also covers (riders there may use both; routing picks one).
module SchoolStops
  class Save < ApplicationService
    def initialize(school, stop, params)
      @school = school
      @stop = stop
      @p = params
    end

    def call
      raise Error, "#{@stop.code} is not in this school's Stop Library" unless Stop.visible_to(@school).exists?(@stop.id)

      ss = SchoolStop.find_or_initialize_by(school: @school, stop: @stop)
      invalid = []
      if @p.key?(:postal_codes)
        codes, invalid = SchoolStops.parse_postals(@p[:postal_codes])
        ss.postal_codes = codes
      end
      ss.areas = areas(@p[:areas]) if @p.key?(:areas)
      ss.off_point_ids = Array(@p[:off_point_ids]).map(&:to_i) & @stop.points.map(&:id) if @p.key?(:off_point_ids)
      if ss.catchment?
        uses = @stop.points.map(&:usage)
        unless uses.intersect?(%w[pickup both]) && uses.intersect?(%w[dropoff both])
          raise Error, "Stops with postal codes or areas need both pick-up and drop-off points"
        end
      end
      ss.save!
      [ ss, invalid, shared(ss) ]
    end

    private

    def areas(list)
      Array(list).map.with_index(1) do |a, i|
        ring = Array(a[:latlngs]).map { |ll| Array(ll).first(2).map(&:to_f) }
        raise Error, "Area #{i} needs at least 3 corners" if ring.size < 3

        { "name" => a[:name].presence, "latlngs" => ring, "exclude" => ActiveModel::Type::Boolean.new.cast(a[:exclude]) || false, "how" => a[:how].presence || "lasso" }
      end
    end

    def shared(ss)
      return [] if ss.postal_codes.empty?

      SchoolStop.where(school: @school).where.not(id: ss.id).where("postal_codes && ARRAY[?]::varchar[]", ss.postal_codes).includes(:stop)
                .flat_map { |o| (o.postal_codes & ss.postal_codes).map { |pc| { postal: pc, stop_code: o.stop.code } } }
    end
  end
end
