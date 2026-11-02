# The SMS text of an invite: own drivers join the company; operator drivers connect with their operator, managed by it.
module Drivers
  module InviteMessage
    def self.for(driver, company)
      if driver.is_a?(OperatorDriver)
        "Invited to connect with #{driver.operator.name}, managed by #{company.name}. Download Convoy Driver to accept"
      else
        "#{company.name} invited you to drive with them on Convoy. Download Convoy Driver to accept"
      end
    end
  end
end
