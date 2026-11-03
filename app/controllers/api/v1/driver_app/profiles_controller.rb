# Convoy Driver app › Account: the portable profile (Personal Details, Complete My Profile, Driving Credentials list,
# Career Metrics) and the email and password used to sign in without a code.
module Api
  module V1
    module DriverApp
      class ProfilesController < BaseController
        # GET /driver/profile
        def show = render_profile

        # PATCH /driver/profile { profile: { name, date_of_birth, nationality, residential_status, id_number, address,
        #                                     postal_code, photo (file), remove_photo } }
        def update
          ::DriverApp::SaveProfile.call(account: current_account, params: params.expect(profile: [ *DriverAccount::PROFILE_FIELDS, :photo, :remove_photo ]))
          render_profile
        end

        # PATCH /driver/profile/email { email, password, password_confirmation, current_password }
        def email
          ::DriverApp::SetEmail.call(account: current_account, **params.permit(:email, :password, :password_confirmation, :current_password).to_h.symbolize_keys)
          render_profile
        end

        private

        def render_profile
          account = current_account.reload
          metrics = ::DriverApp::Metrics.summary(members: account.memberships.reject(&:pending?), current_key: current_driver_jwt.membership_key)
          render json: { data: DriverAccountBlueprint.render_as_hash(account.decorate, view: :profile).merge(metrics:) }
        end
      end
    end
  end
end
