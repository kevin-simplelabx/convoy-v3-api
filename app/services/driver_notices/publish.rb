# Sends a notice to drivers: every active own and operator driver of the company (audience all), or the ones given
# (audience selected). Each gets a recipient row (opened, acknowledged) and a bell line. The Convoy OS screen to write
# notices comes later; the seed uses this.
module DriverNotices
  class Publish < ApplicationService
    def initialize(notice:, members: nil)
      @notice = notice
      @members = members
    end

    def call
      members = @members || (Driver.kept.active.to_a + OperatorDriver.kept.active.to_a)
      now = Time.current
      DriverNotice.transaction do
        @notice.update!(audience: @members ? "selected" : "all")
        members.each do |m|
          key = DriverNotification.member_key(m)
          next if @notice.recipients.exists?(key)

          @notice.recipients.create!(**key)
          DriverNotification.create!(company_id: @notice.company_id, **key, kind: "notice", title: @notice.title, body: @notice.summary,
                                     driver_notice_id: @notice.id, created_at: [ @notice.starts_at, now ].min)
        end
      end
      @notice
    end
  end
end
