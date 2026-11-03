# School Bus Feasibility Studies: students pasted by postal code, planned by the routing engine per scenario, with the
# operator cost, break-even and fares worked out as in Convoy OS (fzParse, fzRun, fzCost, fzFare).
module Feasibility
  LEVEL = /\A(p|k|n|sec|s|gr|grade|y|year|primary|secondary|g)\.?\d{1,2}[a-z]?\z/i

  module_function

  # Lines like "460101, 3, AM, P4" in any order → [{ postal, riders, session, level }] (same postal + session + level add
  # up) and how many lines had no postal code.
  def parse(text)
    out = {}
    bad = 0
    text.to_s.split(/\r?\n/).each_with_index do |line, i|
      cells = line.split(/[,\t;]/).map { it.to_s.strip.delete('"') }
      next if cells.none?(&:present?)

      postal = nil
      n = 1
      session = "both"
      level = nil
      cells.each do |c|
        d = c.gsub(/\s/, "")
        if postal.nil? && d.match?(/\A\d{5,6}\z/) then postal = d.rjust(6, "0")
        elsif postal.nil? && (m = c.match(/(?:\A|\D)(\d{6})(?!\d)/)) then postal = m[1]
        elsif d.match?(/\A\d{1,3}\z/) && d.to_i.positive? then n = d.to_i
        elsif d.match?(/\A(am|morning|pickup)\z/i) then session = "AM"
        elsif d.match?(/\A(pm|afternoon|dropoff)\z/i) then session = "PM"
        elsif d.match?(%r{\A(both|2-?way|twoway|am[&/+]pm|am-pm)\z}i) then session = "both"
        elsif d.match?(LEVEL) then level = c.upcase
        end
      end
      unless postal
        bad += 1 if i.positive?
        next
      end
      key = [ postal, session, level ]
      out[key] ? out[key][:riders] += n : out[key] = { postal:, riders: n, session:, level: }
    end
    [ out.values, bad ]
  end
end
