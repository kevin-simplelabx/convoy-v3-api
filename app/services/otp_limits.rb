# Limits on one-time codes of the Driver app, Client Portal and Convoy App: 5 codes an hour per mobile / email / account,
# and the per-minute throttles of the code steps (config/initializers/rack_attack.rb). Staging turns them all off with
# OTP_LIMITS_OFF=1 so testers can sign in again and again. Never set it in production.
module OtpLimits
  module_function

  def on? = ENV["OTP_LIMITS_OFF"] != "1"
end
