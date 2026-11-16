# Convoy App › Household › Children: Add a Child and edit one (any adult). Removing a child is not designed, so not built.
module Api
  module V1
    module ConvoyApp
      class HouseholdDependantsController < HouseholdBaseController
        # POST /app/household/dependants { dependant: { name, birth_date, school_id | school_name ("Other"), level, gender (girl|boy),
        #   student_id, photo (file), medical_tags [], medical_note } } → the child
        def create
          child = ::ConvoyApp::Households::SaveDependant.call(household:, params: dependant_params)
          render_data(child.decorate, DependantBlueprint, status: :created)
        end

        # PATCH /app/household/dependants/:id (same fields; remove_photo: true clears the photo) → the child
        def update
          child = household.dependants.find { it.id == params[:id].to_i } or raise ActiveRecord::RecordNotFound
          ::ConvoyApp::Households::SaveDependant.call(household:, dependant: child, params: dependant_params)
          render_data(child.decorate, DependantBlueprint)
        end

        private

        def dependant_params
          params.expect(dependant: [ :name, :birth_date, :school_id, :school_name, :level, :gender, :student_id, :photo, :remove_photo,
                                     :medical_note, { medical_tags: [] } ])
        end
      end
    end
  end
end
