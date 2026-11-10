# Moves the old jsonb `area` (a JSON string, one ring [[lat, lng], …] or { add: [rings], sub: [rings] }) into fare_areas
# and the string `targets` (tier ids, "bus:<type>") into fare_adjustment_targets. Rings under 3 corners and targets of
# tiers that no longer exist are dropped (they matched nothing before either); a charge left with no target would then
# apply to every rider, so those charges are listed in the output to check by hand. The old columns are ignored by the
# models and dropped later (strong_migrations: two steps). One transaction: all or nothing.
class BackfillFareAreasAndTargets < ActiveRecord::Migration[8.1]
  def up
    # Data only: inserts into the two new tables, read from columns nothing writes any more; no lock on live tables.
    safety_assured { backfill }
  end

  def down
    safety_assured do
      execute("DELETE FROM fare_areas")
      execute("DELETE FROM fare_adjustment_targets")
    end
  end

  private

  def backfill
    { "fare_tier_id" => "fare_tiers", "fare_surcharge_id" => "fare_surcharges" }.each do |owner, table|
      select_rows("SELECT id, area::text FROM #{table} WHERE area IS NOT NULL").each do |id, raw|
        rings(raw).each_with_index do |(ring, exclude), i|
          execute(sanitize([ "INSERT INTO fare_areas (#{owner}, position, exclude, ring) VALUES (?, ?, ?, ?::float8[])", id, i + 1, exclude, pg_array(ring) ]))
        end
      end
    end

    orphans = []
    select_rows("SELECT id, targets FROM fare_adjustments WHERE cardinality(targets) > 0").each do |id, raw|
      PG::TextDecoder::Array.new.decode(raw).uniq.each do |t|
        if t.start_with?("bus:")
          execute(sanitize([ "INSERT INTO fare_adjustment_targets (fare_adjustment_id, bus_type) VALUES (?, ?) ON CONFLICT DO NOTHING", id, t.delete_prefix("bus:") ]))
        elsif t.match?(/\A\d+\z/)
          execute(sanitize([ "INSERT INTO fare_adjustment_targets (fare_adjustment_id, fare_tier_id) SELECT ?, id FROM fare_tiers WHERE id = ? ON CONFLICT DO NOTHING", id, t.to_i ]))
        end
      end
      orphans << id if select_value("SELECT count(*) FROM fare_adjustment_targets WHERE fare_adjustment_id = #{id.to_i}").to_i.zero?
    end
    say "Extra Charges whose targets all point to deleted tiers (now apply to every rider, check them): #{orphans.join(', ')}" if orphans.any?
  end

  def sanitize(args) = ActiveRecord::Base.sanitize_sql_array(args)
  def pg_array(ring) = "{#{ring.map { "{#{it.join(',')}}" }.join(',')}}"

  # [[ring, exclude], …] from any of the old shapes.
  def rings(raw)
    v = JSON.parse(raw)
    v = JSON.parse(v) if v.is_a?(String)
    list = if v.is_a?(Hash)
             Array(v["add"]).map { [ it, false ] } + Array(v["sub"]).map { [ it, true ] }
    elsif v.is_a?(Array) && v.first.is_a?(Array) && v.first.first.is_a?(Array)
             v.map { [ it, false ] }
    else
             [ [ v, false ] ]
    end
    list.filter_map do |ring, exclude|
      pts = Array(ring).filter_map { |ll| ll.is_a?(Array) && ll.size >= 2 ? ll.first(2).map { Float(it) } : nil }
      [ pts, exclude ] if pts.size >= 3
    end
  rescue JSON::ParserError, ArgumentError, TypeError
    []
  end
end
