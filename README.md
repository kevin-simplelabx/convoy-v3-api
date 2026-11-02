# Convoy v3 API

Rails 8.1 API for the Convoy OS Scheduler. Plan, phases and decisions: `.notes/`.

## Setup
```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails s
bundle exec rspec
```

Claude (document reading): set `ANTHROPIC_API_KEY` in `.env` (or `anthropic.api_key` in credentials).

Sample sign-in: `ops@simpledrive.sg` / `Simple123!` (see `.notes/10-phase-0-foundation.md`).
