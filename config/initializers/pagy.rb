require "pagy/extras/overflow"
require "pagy/extras/limit"

Pagy::DEFAULT[:limit] = 50
Pagy::DEFAULT[:limit_max] = 500
Pagy::DEFAULT[:overflow] = :empty_page
