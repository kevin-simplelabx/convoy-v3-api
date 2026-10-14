class CompanyBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :logo, :created_at

  view :with_stats do
    field :users_count do |company|
      company.users.count
    end

    field :admin_email do |company|
      company.users.find_by(role: "admin")&.email || ""
    end
  end
end
