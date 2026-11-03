# The Dashboard's widgets (prototype Company Dashboard.dc.html W / SZ / SEC): section, title, icon, the page it opens,
# default size in grid cells (8 columns, rows of 150 px), and who may see it. A grid has up to 6 pages.
module Dashboard
  module Catalogue
    module_function

    COLS = 8
    MAX_PAGES = 6

    SECTIONS = [ { key: "ops", title: "Operations" }, { key: "fleet", title: "Fleet and People" },
                 { key: "money", title: "Money" }, { key: "cl", title: "Clients" } ].freeze

    # key => [section, title, icon, page, link label, [cols, rows], permissions (any of; nil = everyone)]
    WIDGETS = {
      "otp" => [ "ops", "On-Time Starts", "schedule", "opsctl", "Ops Control", [ 4, 2 ], nil ],
      "late" => [ "ops", "Late Starts and Missed Pick-ups", "running_with_errors", "opsctl", "Ops Control", [ 2, 2 ], nil ],
      "today" => [ "ops", "Trips", "assignment", "trips", "Trips", [ 2, 2 ], nil ],
      "unas" => [ "ops", "Unassigned Trips", "assignment_late", "scheduler", "Scheduler", [ 2, 2 ], nil ],
      "alerts" => [ "ops", "Open Ops Control Alerts", "notification_important", "opsctl", "Ops Control", [ 2, 2 ], nil ],
      "compl" => [ "ops", "Complaints and Incidents", "report", "triphist", "Trip History", [ 2, 1 ], nil ],
      "util" => [ "fleet", "Fleet Utilisation", "speed", "vehicles", "Vehicles", [ 4, 2 ], nil ],
      "off" => [ "fleet", "Vehicles Off the Road", "car_repair", "vehicles", "Vehicles", [ 2, 2 ], nil ],
      "docs" => [ "fleet", "Documents Expiring", "event_busy", "vehicles", "Vehicles", [ 2, 2 ], nil ],
      "duty" => [ "fleet", "Drivers", "badge", "drivers", "Drivers", [ 2, 2 ], nil ],
      "noshow" => [ "fleet", "Driver No-Shows", "person_off", "drivers", "Drivers", [ 2, 2 ], nil ],
      "rev" => [ "money", "Revenue", "trending_up", "vehfin", "Vehicle Financials", [ 2, 2 ], %i[finance finview vehfin] ],
      "profit" => [ "money", "Fleet Profit", "savings", "vehfin", "Vehicle Financials", [ 4, 3 ], %i[vehfin] ],
      "topbot" => [ "money", "Vehicles by Profit", "leaderboard", "vehfin", "Vehicle Financials", [ 2, 3 ], %i[vehfin] ],
      "coll" => [ "money", "Collections", "request_quote", "cfcol", "Collections", [ 2, 2 ], %i[finance finview] ],
      "opp" => [ "money", "Operator Payments", "payments", "cfpay", "Operator Payments", [ 2, 2 ], %i[finance finview] ],
      "loans" => [ "money", "Loan Instalments", "account_balance", "vehfin", "Vehicle Financials", [ 2, 2 ], %i[vehfin] ],
      "clotp" => [ "cl", "On-Time Starts by Client", "corporate_fare", "clients", "Clients", [ 4, 2 ], nil ],
      "clrisk" => [ "cl", "Clients at Risk", "warning", "clients", "Clients", [ 2, 2 ], nil ]
    }.freeze

    def allowed?(user, key)
      perms = WIDGETS.fetch(key)[6]
      perms.nil? || user.convoy_admin? || perms.any? { |p| user.can?(p) }
    end

    def for(user)
      WIDGETS.select { |k, _| allowed?(user, k) }.map do |k, (section, title, icon, page, link, size, _)|
        { key: k, section:, title:, icon:, page:, link:, cols: size[0], rows: size[1] }
      end
    end

    # One Overview page with every widget the user may see, placed left to right, top to bottom.
    def default_layout(user)
      x = y = row_h = 0
      items = self.for(user).map do |w|
        if x + w[:cols] > COLS
          y += row_h
          x = row_h = 0
        end
        item = { widget: w[:key], x:, y:, cols: w[:cols], rows: w[:rows] }
        x += w[:cols]
        row_h = [ row_h, w[:rows] ].max
        item
      end
      [ { name: "Overview", items: } ]
    end
  end
end
