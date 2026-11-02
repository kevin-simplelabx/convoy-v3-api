# Times of day are stored as minutes after midnight (may pass 1440 for trips past midnight) and shown as "HH:MM".
module Clock
  module_function

  # "07:30" -> 450; 450 -> 450; "" -> nil. Raises ArgumentError on anything else.
  def minutes(value)
    case value
    when nil, "" then nil
    when Integer then value
    when /\A(\d{1,2}):(\d{2})\z/ then (::Regexp.last_match(1).to_i * 60) + ::Regexp.last_match(2).to_i
    when /\A\d+\z/ then value.to_i
    else raise ArgumentError, "#{value.inspect} is not a time (HH:MM)"
    end
  end

  # 450 -> "07:30"; 1500 -> "01:00" (wraps past midnight).
  def hm(minutes)
    return nil if minutes.nil?

    m = minutes % 1440
    format("%02d:%02d", m / 60, m % 60)
  end
end
