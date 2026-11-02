# HR > Audit Log: changes to rate plans, pay schemes, bonuses, rewards, driver assignments, points and confirmed months,
# read from `audits` (only the current company's records), newest first, with an action, an item and a sentence.
module Pay
  class AuditLog < ApplicationService
    ITEMS = { "PayRatePlan" => "rate_plan", "PayScheme" => "pay_scheme", "PayBonus" => "campaign_bonus", "PayReward" => "reward",
              "DriverPayScheme" => "driver_assignment", "DriverVehicleType" => "driver_assignment", "DriverPayMonth" => "driver_pay",
              "DriverPointLot" => "points", "DriverPointDeduction" => "points" }.freeze
    ITEM_LABELS = { "rate_plan" => "Rate Plan", "pay_scheme" => "Pay Scheme", "campaign_bonus" => "Bonus", "reward" => "Reward",
                    "driver_assignment" => "Driver", "driver_pay" => "Driver Pay", "points" => "Points" }.freeze
    ACTIONS = %w[create update delete lock unlock award deduct confirm reopen].freeze
    LIMIT = 500

    def initialize(q: nil, action: nil, item: nil)
      @q = q.to_s.strip.downcase.presence
      @action = action.presence
      @item = item.presence
    end

    def call
      types = ITEMS.select { |_t, i| @item.nil? || i == @item }.keys
      rows = company_scope(types).includes(:user).order(created_at: :desc, id: :desc).limit(LIMIT).to_a
      names = names_for(rows)
      rows.map { |a| entry(a, names) }.select { |e| (@action.nil? || e[:action] == @action) && matches?(e) }
    end

    private

    # Only audits of records of the current company (the audits table has no company).
    def company_scope(types)
      company = ActsAsTenant.current_tenant
      types.map do |t|
        ids = t.constantize.unscoped.where(company_id: company.id).select(:id)
        Audited::Audit.where(auditable_type: t, auditable_id: ids)
      end.reduce(:or)
    end

    # { [type, id] => name } of the records (deleted ones keep their name in the audit).
    def names_for(rows)
      rows.group_by(&:auditable_type).each_with_object({}) do |(type, list), out|
        model = type.constantize
        records = (model.respond_to?(:with_discarded) ? model.with_discarded : model).where(id: list.map(&:auditable_id)).to_a
        records.each { |r| out[[ type, r.id ]] = name_of(r) }
      end
    end

    def name_of(r)
      case r
      when DriverPayScheme, DriverVehicleType, DriverPayMonth, DriverPointLot, DriverPointDeduction then r.driver&.name
      when PayReward then r.title
      else r.name
      end
    end

    def entry(a, names)
      item = ITEMS[a.auditable_type]
      name = names[[ a.auditable_type, a.auditable_id ]] || a.audited_changes&.values_at("name", "title")&.compact&.first
      { id: a.id, at: a.created_at, user: a.user&.try(:shown_name) || a.username, action: action_of(a, item), item:,
        item_label: ITEM_LABELS[item], name:, details: details(a) }
    end

    def action_of(a, item)
      return a.action == "create" ? "confirm" : "reopen" if item == "driver_pay"
      return a.auditable_type == "DriverPointLot" ? "award" : "deduct" if item == "points" && a.action == "create"
      return "lock" if a.comment == "Locked"
      return "unlock" if a.comment == "Unlocked"

      { "create" => "create", "destroy" => "delete" }.fetch(a.action, "update")
    end

    def details(a)
      return nil if %w[Locked Unlocked].include?(a.comment)
      return a.comment if a.comment.present?

      c = a.audited_changes || {}
      case a.auditable_type
      when "DriverPayScheme", "DriverVehicleType"
        what = a.auditable_type == "DriverPayScheme" ? "scheme" : "vehicle type"
        case a.action
        when "create" then "Assigned a #{what} from #{fmt(c['starts_on'])}"
        when "destroy" then "Removed the #{what} assignment from #{fmt(c['starts_on'])}"
        else c.map { |k, (_from, to)| "#{k.humanize} changed to #{fmt(to) || 'none'}" }.join(", ")
        end
      else
        return "Created" if a.action == "create"
        return "Deleted" if a.action == "destroy"

        (c.keys - %w[updated_at locked_at locked_by_id]).map(&:humanize).join(", ").presence
      end
    end

    def fmt(value) = value && (Date.parse(value.to_s).strftime("%-d %b %Y") rescue value.to_s) # rubocop:disable Style/RescueModifier

    def matches?(e)
      @q.nil? || [ e[:user], e[:name], e[:details] ].compact.any? { |s| s.to_s.downcase.include?(@q) }
    end
  end
end
