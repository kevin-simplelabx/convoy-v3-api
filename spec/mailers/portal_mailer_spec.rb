require "rails_helper"

RSpec.describe PortalMailer do
  it "emails the one-time code" do
    mail = described_class.sign_in_code(PortalAccount.new(email: "priya@google.com"), "123456", "reset")
    expect(mail.to).to eq([ "priya@google.com" ])
    expect(mail.subject).to eq("123456 is your Client Portal code")
    expect(mail.text_part.body.to_s).to include("set a new password", "123456", "15 minutes")
  end
end
