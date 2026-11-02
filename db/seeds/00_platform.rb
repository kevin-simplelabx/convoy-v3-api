# Convoy Admin (platform) and the sample transport company SimpleDrive with its users.
User.find_or_initialize_by(email: "admin@convoy.sg").tap do |u|
  u.assign_attributes(name: "Convoy Admin", role: :convoy_admin, company: nil)
  u.password = "Convoy123!" if u.new_record?
  u.save!
end

simpledrive = Company.find_or_initialize_by(code: "SD").tap do |c|
  c.assign_attributes(name: "SimpleDrive", short_name: "SimpleDrive", country: "SG",
                      timezone: "Asia/Singapore", theme_color: "#0B6E6E")
  c.save!
end

[
  { email: "ops@simpledrive.sg", name: "SimpleDrive Ops", role: :admin, owner: true, password: "Simple123!" },
  { email: "dispatch@simpledrive.sg", name: "Rachel Tan", role: :member, permissions: %w[vehicles], password: "Simple123!" },
  { email: "finance@simpledrive.sg", name: "Marcus Lim", role: :member, permissions: %w[finance finview vehfin], password: "Simple123!" }
].each do |attrs|
  User.find_or_initialize_by(email: attrs[:email]).tap do |u|
    u.assign_attributes(attrs.except(:email, :password).merge(company: simpledrive))
    u.password = attrs[:password] if u.new_record?
    u.save!
  end
end
