# Convoy App › Create Your Account and Account: name (Show My Name As), photo, notification switches; Privacy and Data ›
# Delete Account.
module Api
  module V1
    module ConvoyApp
      class ProfilesController < BaseController
        skip_before_action :require_profile!, only: %i[show update]

        # GET /app/profile
        def show = render_data(current_account.decorate, AppAccountBlueprint)

        # PATCH /app/profile { profile: { first_name, last_name, name_order (first|last), accept_terms (true), photo (file),
        #                                 remove_photo, notify_push, notify_sms, notify_email } }
        def update
          ::ConvoyApp::SaveProfile.call(account: current_account,
                                        params: params.expect(profile: %i[first_name last_name name_order accept_terms photo remove_photo
                                                                          notify_push notify_sms notify_email]))
          render_data(current_account.reload.decorate, AppAccountBlueprint)
        end

        # DELETE /app/profile — Delete Account: removed after 30 days unless they sign in again; every phone is signed out.
        def destroy
          ::ConvoyApp::RequestDelete.call(account: current_account)
          render json: { data: { delete_on: (current_account.delete_requested_at + AppAccount::DELETE_AFTER).to_date } }
        end
      end
    end
  end
end
