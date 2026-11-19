require "rails_helper"

# HR > Pay Schemes and Bonuses: Unlock (Admin only; written to the HR audit log), then the record can be saved again.
RSpec.describe "HR pay unlock" do
  let(:company) { create(:company) }
  let(:finance) { create(:user, company:, permissions: %w[finance]) }
  let(:admin) { create(:user, :admin, company:) }
  let!(:plan) { within_tenant(company) { PayRatePlan.create!(name: "Standard") } }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(finance)
  end

  def scheme(**attrs) = { scheme: { name: "Basic + Trips", scheme_type: "basic_plus_trips", pay_rate_plan_id: plan.id }.merge(attrs) }
  def bonus(**attrs) = { bonus: { name: "Nov Trip Bonus", plan_type: "trip_target", frequency: "monthly", starts_on: "2026-11-01",
                                  tiers: [ { target_trips: 3, pay_as: "lump_sum", amount: 100 } ] }.merge(attrs) }

  {
    "pay scheme" => { model: PayScheme, body: :scheme, collection: :api_v1_pay_schemes_path, member: :api_v1_pay_scheme_path,
                      unlock: :unlock_api_v1_pay_scheme_path, name: "Basic + Trips" },
    "bonus" => { model: PayBonus, body: :bonus, collection: :api_v1_pay_bonuses_path, member: :api_v1_pay_bonus_path,
                 unlock: :unlock_api_v1_pay_bonus_path, name: "Nov Trip Bonus" }
  }.each do |label, c|
    describe label do
      def locked_id(c)
        post public_send(c[:collection]), params: send(c[:body]).merge(lock: true), as: :json
        expect(json[:data]).to include(locked: true), json.inspect
        json.dig(:data, :id)
      end

      def comments(c, id) = within_tenant(company) { c[:model].find(id).audits.where.not(comment: nil).pluck(:comment) }

      it "is unlocked by an Admin, audited, and can then be saved" do
        id = locked_id(c)
        sign_in_as(admin)
        patch public_send(c[:member], id), params: send(c[:body], description: "x"), as: :json
        expect(json.dig(:error, :message)).to eq("#{c[:name]} is locked. Unlock it to make changes")

        post public_send(c[:unlock], id)
        expect(response).to have_http_status(:ok)
        expect(json[:data]).to include(locked: false, locked_at: nil, locked_by: nil)
        expect(comments(c, id)).to eq(%w[Locked Unlocked])

        post public_send(c[:unlock], id) # already unlocked: nothing more written
        expect(json[:data]).to include(locked: false)
        expect(comments(c, id)).to eq(%w[Locked Unlocked])

        sign_in_as(finance)
        patch public_send(c[:member], id), params: send(c[:body], description: "New wording"), as: :json
        expect(response).to have_http_status(:ok), json.inspect
        expect(json[:data]).to include(description: "New wording", locked: false)
      end

      it "is refused to a non-Admin and to another company" do
        id = locked_id(c)
        post public_send(c[:unlock], id)
        expect(response).to have_http_status(:forbidden)

        sign_in_as(create(:user, :admin, company: create(:company)))
        post public_send(c[:unlock], id)
        expect(response).to have_http_status(:not_found)
        expect(within_tenant(company) { c[:model].find(id).locked? }).to be(true)
      end
    end
  end
end
