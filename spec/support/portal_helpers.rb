# Client Portal request specs: a client user with a portal password, and a token with that client account picked.
module PortalHelpers
  def portal_user(client, email:, role:, sites: [], name: email.split("@").first.capitalize)
    account = PortalAccount.for_email!(email, name:)
    account.update!(password: "Portal123!", password_set_at: Time.current) unless account.password_set?
    user = client.users.create!(company_id: client.company_id, name:, email:, role:, portal_account: account)
    sites.each { |s| user.user_sites.create!(client_site: s) }
    user
  end

  def portal_token(user)
    integration_session.bearer_token = nil
    post api_v1_portal_session_path, params: { email: user.email, password: "Portal123!" }, as: :json
    token = json.dig(:data, :token)
    patch api_v1_portal_session_path, params: { client_user_id: user.id }, headers: as(token), as: :json
    token
  end
end

RSpec.configure { it.include PortalHelpers, type: :request }
