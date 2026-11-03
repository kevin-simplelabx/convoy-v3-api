# Convoy Driver app: sign-in by mobile number, the companies a driver works for, and (later phases) their runs.
module DriverApp
  module_function

  # The one-time code. No SMS provider yet, so it is always the same (DRIVER_OTP_CODE, default 123456) and nothing is
  # sent; swap this for a random code once SMS goes out.
  def otp_code = ENV["DRIVER_OTP_CODE"].presence || "123456"
end
