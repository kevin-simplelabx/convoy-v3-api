# Phone numbers are stored as E.164 (default region Singapore, see config/initializers/phonelib.rb); a number Phonelib
# cannot read as valid keeps only its digits and "+", so the validation message can still show what was typed.
#   normalizes :phone, with: PhoneNormalizer
module PhoneNormalizer
  def self.call(value)
    Phonelib.parse(value).then { |p| p.valid? ? p.e164 : value.to_s.gsub(/[^\d+]/, "") }
  end
end
