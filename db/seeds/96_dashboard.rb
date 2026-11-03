# Dashboard: the dispatcher keeps a two-page layout (Operations first, Fleet on its own page); others see the default.
with_company("SD") do
  user = User.find_by!(email: "dispatch@simpledrive.sg")
  DashboardLayout.find_or_create_by!(user:) do |l|
    l.pages = [
      { "name" => "Today", "items" => [ { "widget" => "otp", "x" => 0, "y" => 0, "cols" => 4, "rows" => 2 },
                                        { "widget" => "late", "x" => 4, "y" => 0, "cols" => 2, "rows" => 2 },
                                        { "widget" => "unas", "x" => 6, "y" => 0, "cols" => 2, "rows" => 2 },
                                        { "widget" => "today", "x" => 0, "y" => 2, "cols" => 2, "rows" => 2 } ] },
      { "name" => "Fleet", "items" => [ { "widget" => "util", "x" => 0, "y" => 0, "cols" => 4, "rows" => 2 },
                                        { "widget" => "docs", "x" => 4, "y" => 0, "cols" => 2, "rows" => 2 },
                                        { "widget" => "off", "x" => 6, "y" => 0, "cols" => 2, "rows" => 2 } ] }
    ]
  end
end
