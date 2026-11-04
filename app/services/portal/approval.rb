# A Client Portal booking's approval (logic/app-feed.js apprCan, stepDone, apprAct), on a BookingApproval kept as it
# was when the booking was sent. Steps run in order. Who may decide the current step: the people it asked who are still
# right for it (named people while not removed; a group's people while still in the group and covering the site; the
# Admins it fell to while still Admins), or any Super Admin / Admin (step in); never the booker; nobody twice on a step;
# with same_person "other", not someone who approved an earlier step unless no one else is left. A step is done when
# any one approves, or, for "everyone", when all its people still right for it (less those skipped) have approved.
# Approving the last step sends the trips to the transport company; a decline (with the reason) declines every trip
# still waiting. same_person "once": people on the next step who approved an earlier one count as approved (carried).
module Portal
  class Approval
    INCLUDES = [ { acts: :client_user }, { booking: [ :client, :created_by_client_user ],
                          steps: { step_people: { client_user: [ :client, :user_sites, :manager, { team: :manager } ] } } } ].freeze

    # On Submit: the approval the route asked for (nothing when the flow is off).
    def self.start!(booking:, route:)
      return unless route.flow&.on?

      approval = booking.create_approval!(company_id: booking.company_id, rule: route.rule, name: route.name,
                                          flow_kind: route.flow.organisation? ? "organisation" : "site", same_person: route.same_person,
                                          status: route.need ? "wait" : "none", current_step: route.need ? 1 : 0,
                                          decided_at: (Time.current unless route.need))
      booker = booking.created_by_client_user
      route.steps.each.with_index(1) do |s, position|
        step = approval.steps.create!(position:, who: s.who, need: s.need, label: s.label, fallback: s.fallback)
        s.people.each do |u|
          reason = if s.fallback then "fallback"
          elsif ApprovalRoute.in_group?(u, who: s.who, site_id: booking.client_site_id, booker:) then "group"
          else "named"
          end
          step.step_people.create!(client_user: u, reason:)
        end
      end
      approval
    end

    def self.for(booking) = new(BookingApproval.includes(*INCLUDES).find_by!(booking:))

    attr_reader :approval

    def initialize(approval)
      @approval = approval
      @booking = approval.booking
      @booker = @booking.created_by_client_user
    end

    def step = @approval.current
    def acts_on(step) = @approval.acts.select { it.booking_approval_step_id == step.id }

    # The people a step asked who are still right for it.
    def people(step)
      step.step_people.select { still_right?(it, step) }.map(&:client_user)
    end

    # Who the current step waits for: its people still right for it who have not decided (else the Admins).
    def waiting_for
      return [] unless @approval.waiting?

      skipped = skipped_ids(step)
      left_out = acts_on(step).map(&:client_user_id) + [ @booker&.id ] + (someone_else?(step, skipped) ? skipped : [])
      people(step).reject { left_out.include?(it.id) }.presence || admins.reject { left_out.include?(it.id) }
    end

    def can_decide?(user)
      return false unless @approval.waiting? && step && user&.kept?
      return false if user.id == @booker&.id || acts_on(step).any? { it.client_user_id == user.id }

      skipped = skipped_ids(step)
      return false if skipped.include?(user.id) && someone_else?(step, skipped)

      people(step).include?(user) || admin?(user)
    end

    # Deciding without being one of the step's people (a Super Admin or Admin stepping in).
    def stepping_in?(user) = can_decide?(user) && people(step).exclude?(user)

    def approve!(user, note: nil)
      decide!(user) do
        @approval.acts.create!(step:, client_user: user, act: "approve", note: note.presence)
        advance!(user)
      end
    end

    def decline!(user, note:)
      raise ApplicationService::Error, "Say why it is declined, the person who booked sees it" if note.blank?

      decide!(user) do
        @approval.acts.create!(step:, client_user: user, act: "decline", note: note.squish)
        @approval.update!(status: "no", decided_at: Time.current)
        waiting_trips.each do |t|
          t.client_decline
          t.assign_attributes(rejected_at: Time.current, rejection_reason: note.squish)
          t.stamp_actor(:rejected, user).save!
        end
        @booking.update!(estimate_amount: @booking.trips.reload.to_a.sum { it.rejected? || it.cancelled? ? 0 : it.estimate_amount })
        notify("client_declined", "Declined by #{user.name} in #{client_name}'s approval flow: #{note.squish}", user)
      end
    end

    private

    def decide!(user)
      BookingApproval.transaction do
        @approval.lock!
        raise Pundit::NotAuthorizedError, "You cannot decide this booking now" unless can_decide?(user)

        yield
      end
      self
    end

    def advance!(user)
      while done?(step)
        if step.position == @approval.steps.size
          finish!(user)
          break
        end
        @approval.update!(current_step: step.position + 1)
        carry!(step) if @approval.same_person == "once"
      end
    end

    def finish!(user)
      @approval.update!(status: "ok", decided_at: Time.current)
      waiting_trips.each { it.client_approve! }
      notify("client_approved", "Approved by #{user.name} in #{client_name}'s approval flow, sent to you", user)
    end

    # same_person "once": someone on this step who approved an earlier one counts as approved here too.
    def carry!(step)
      earlier = @approval.acts.select { it.approve? && position_of(it) < step.position }.group_by(&:client_user_id)
      people(step).each do |u|
        next if u.id == @booker&.id || earlier[u.id].blank? || acts_on(step).any? { it.client_user_id == u.id }

        @approval.acts.create!(step:, client_user: u, act: "approve", carried_from: earlier[u.id].map { position_of(it) }.min)
      end
    end

    def done?(step)
      approved = acts_on(step).select(&:approve?).map(&:client_user_id)
      return approved.any? unless step.need == "all"

      everyone = people(step).map(&:id) - skipped_ids(step) - [ @booker&.id ]
      everyone.any? ? (everyone - approved).empty? : approved.any?
    end

    # same_person "other": people who approved an earlier step are left out of this one.
    def skipped_ids(step)
      return [] unless @approval.same_person == "other"

      @approval.acts.select { it.approve? && position_of(it) < step.position }.map(&:client_user_id).uniq
    end

    def position_of(act) = @approval.steps.find { it.id == act.booking_approval_step_id }.position

    def someone_else?(step, skipped)
      people(step).any? { skipped.exclude?(it.id) } || admins.any? { skipped.exclude?(it.id) }
    end

    def still_right?(person, step)
      u = person.client_user
      return false unless u.kept?

      case person.reason
      when "named" then true
      when "fallback" then admin?(u)
      else ApprovalRoute.in_group?(u, who: step.who, site_id: @booking.client_site_id, booker: @booker)
      end
    end

    def admin?(user) = user.super? || user.adm?
    def admins = @admins ||= @booking.client.users.kept.where(role: %w[super adm]).where.not(id: @booker&.id).order(:name).to_a
    def waiting_trips = @booking.trips.reload.select(&:awaiting_client?)
    def client_name = @booking.client.name

    def notify(kind, message, user)
      Bookings::Notify.call(booking: @booking, kind:, message:, actor_name: user.name)
    end
  end
end
