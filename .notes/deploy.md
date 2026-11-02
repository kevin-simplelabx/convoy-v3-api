# Deploy (staging) — Kamal 2

- Server: EC2 Ubuntu 26.04, x86_64, 2 CPU / 4GB, `ssh convoy-v3-stg` (user `deployer`, sudo cần mật khẩu, đã ở group `docker`).
  IP `13.229.92.162` **chưa gắn Elastic IP** → stop/start instance là đổi IP: sửa `config/deploy.yml`, DNS, `~/.ssh/config`.
- Domain: `https://convoy-api-staging.convoy.sg` (A record → IP). SSL do kamal-proxy lấy Let's Encrypt tự động.
- Security Group mở 22, 80, 443.

## Thành phần
| Gì | Ở đâu |
| --- | --- |
| App (Puma + Thruster + Solid Queue trong Puma) | container `convoy_v3-web-<version>`, `RAILS_ENV=production` |
| Postgres 17 | accessory `convoy_v3-db`, data ở `~/convoy_v3-db/data` trên server, chỉ mở `127.0.0.1:5432` |
| 4 DB | `convoy_v3_production` (+ `_cache`, `_queue`, `_cable`), `db:prepare` tự tạo lúc container khởi động |
| File upload (CarrierWave) | volume docker `convoy_v3_storage` → `/rails/storage` |
| Image registry | GHCR `ghcr.io/kevin-simplelabx/convoy-v3-api` (private). Mac push, server pull thẳng từ GitHub. Bỏ `localhost:5555` (SSH tunnel) vì mạng reset luồng lớn → `IOError: closed stream` |

## Secrets (không commit)
`.kamal/secrets` chỉ tham chiếu: `config/master.key`, `.kamal/registry_token` (GitHub token classic `write:packages`), `.kamal/db_password` (mật khẩu Postgres, sinh 1 lần bằng `openssl rand -hex 24`, gitignored).
Mất `.kamal/db_password` thì lấy lại: `ssh convoy-v3-stg 'docker exec convoy_v3-db env | grep POSTGRES_PASSWORD'`.

## ENV staging (`config/deploy.yml` → `env.clear`)
- `CORS_ALLOW_LOCALHOST=true` — chấp nhận origin `localhost` / `127.0.0.1` mọi port (`config/initializers/cors.rb`).
- Đăng nhập bằng Bearer token (JWT) nên không có vấn đề cookie / Safari. Secret JWT = `secret_key_base` (đặt `DEVISE_JWT_SECRET_KEY` nếu muốn tách).
- `ANTHROPIC_API_KEY` chưa đặt (tính năng AI chưa test). Khi cần: thêm vào `env.secret` + `.kamal/secrets`.
- `SOLVER_URL`, `OSRM_URL`, `DEMO_LOGIN`, `DEVISE_SECRET_KEY` trong `.env` không được Rails dùng (sót từ prototype).

## Lệnh
Chạy trong `convoy-v3-api/` (`source ~/.rvm/scripts/rvm && rvm use 3.4.2`). Kamal build từ **commit HEAD** → commit trước khi deploy.
| Việc | Lệnh |
| --- | --- |
| Lần đầu (proxy + Postgres + app) | `bin/kamal setup` |
| Seed (idempotent) | `bin/kamal seed` |
| Deploy code mới | `bin/kamal deploy` |
| Log | `bin/kamal logs` |
| Rails console / DB / shell | `bin/kamal console` · `bin/kamal dbc` · `bin/kamal shell` |
| Quay lại bản trước | `bin/kamal rollback <version>` (xem version: `bin/kamal app containers`) |
| Trạng thái | `bin/kamal details` |
| Restart Postgres | `bin/kamal accessory reboot db` |
| Kiểm tra occurrence | `bin/kamal app exec "bin/rails occurrences:verify"` |
| Mở DB từ Mac (TablePlus...) | `ssh -L 5433:127.0.0.1:5432 convoy-v3-stg` rồi nối `localhost:5433`, user `convoy_v3` |

## Lưu ý
- Seed tạo tài khoản mẫu mật khẩu công khai (`CLAUDE.md`) trên server public → đổi mật khẩu khi có người ngoài dùng.
- Thêm Redis / Sidekiq sau: Redis = `accessories`, Sidekiq = role mới trong `servers` (`cmd: bundle exec sidekiq`).
- SSH từ Mac bị reset lúc bắt tay với KEX `mlkem768` (gói lớn, do mạng giữa đường): thêm `KexAlgorithms curve25519-sha256` vào `~/.ssh/config` của host.
- Code: GitHub `kevin-simplelabx/convoy-v3-api` (private).
