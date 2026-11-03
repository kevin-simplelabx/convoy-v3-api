# Convoy Admin > Transport Companies > New Company: the company and its first Admin (Super Admin of the company, who
# signs in with the email and password given). The code (2–6 letters / digits) is made from the name when not given.
module Companies
  class Create < ApplicationService
    def initialize(params:, admin:)
      @params = params
      @admin = admin.to_h.symbolize_keys
    end

    def call
      raise Error, "Enter the admin's name" if @admin[:name].blank?
      raise Error, "Password needs at least 8 characters" if @admin[:password].to_s.size < 8

      Company.transaction do
        company = Company.new(@params)
        company.code = free_code(company.name) if company.code.blank?
        company.save!
        ActsAsTenant.with_tenant(company) do
          User.create!(company:, name: @admin[:name], email: @admin[:email], password: @admin[:password], role: "admin", owner: true,
                       permissions: User::PERMISSIONS)
        end
        company
      end
    end

    private

    def free_code(name)
      base = name.to_s.upcase.scan(/[A-Z0-9]+/).map { |w| w[0] }.join.presence || name.to_s.upcase.gsub(/[^A-Z0-9]/, "")
      base = base[0, 4].ljust(2, "X")
      code = base
      n = 1
      code = "#{base}#{n += 1}"[0, 6] while Company.exists?(code:)
      code
    end
  end
end
