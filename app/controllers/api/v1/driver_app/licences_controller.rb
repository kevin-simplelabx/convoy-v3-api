# Convoy Driver app › Account › Driving Credentials: add, update and remove the driver's licences (card photos as files).
module Api
  module V1
    module DriverApp
      class LicencesController < BaseController
        # POST /driver/licences { licence: { kind, name, classes, number, issued_on, expires_on, card_front, card_back } }
        def create
          render_data save, DriverLicenceBlueprint, status: :created
        end

        # PATCH /driver/licences/:id { licence: { …, remove_card_front, remove_card_back } }
        def update
          render_data save(licence), DriverLicenceBlueprint
        end

        # DELETE /driver/licences/:id
        def destroy
          ::DriverApp::SaveLicence.call(account: current_account, licence:, remove: true)
          head :no_content
        end

        private

        def licence = current_account.licences.find(params[:id])

        def save(record = nil)
          fields = [ *::DriverApp::SaveLicence::FIELDS, :card_front, :card_back, :remove_card_front, :remove_card_back ]
          ::DriverApp::SaveLicence.call(account: current_account, licence: record, params: params.expect(licence: fields)).decorate
        end
      end
    end
  end
end
