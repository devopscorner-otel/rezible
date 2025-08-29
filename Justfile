set shell := ["bash", "-uc"]
set dotenv-load

frontend_dist_dir := "./backend/internal/http/frontend-dist"
saml_cert_dir := "./backend/internal/saml/testdata"

_default:
  @just --list

# [group('Setup')]

@setup:
    mkdir -p "{{ saml_cert_dir }}"
    mkdir -p "{{ frontend_dist_dir }}" && echo "<p>this will be replaced by the frontend build</p>" > "{{ frontend_dist_dir }}/index.html"
    openssl req -x509 -newkey rsa:2048 -keyout "{{ saml_cert_dir }}/test.key" -out "{{ saml_cert_dir }}/test.cert" -days 365 -nodes -subj "/CN=test.rezible.com"
    just install-dependencies
    just codegen
    just setup-db

@install-dependencies:
    cd backend && go mod tidy
    bun install

@upgrade-everything:
    devbox update
    cd backend && go get -u ./... && go mod tidy
    bun update

@run-backend *ARGS:
    cd backend && SERVICE_DB_URL="$DB_URL" SERVICE_DEBUG=true go run ./cmd/rezible {{ARGS}}

# [group('Code Generation')]

@codegen: codegen-backend && codegen-frontend

@codegen-ent:
    cd backend && go generate ./ent

@codegen-backend:
    cd backend && go generate ./...

@codegen-frontend:
    just run-backend openapi > /tmp/rezible-spec.yaml
    cd frontend && bun run codegen

# [group('Development')]

@dev: stop-db
    process-compose --ordered-shutdown

@format:
    cd backend && go fmt ./...
    cd frontend && bun run format

@dev-backend:
    cd backend && reflex -s -d none -r '\.go$' -- just run-backend

@dev-frontend:
    cd frontend && bun run dev

@dev-document-server:
    cd documents && bun run dev

# [group('Database')]
@setup-db: stop-db
    rm -rf ./.devbox/virtenv/postgresql/data
    initdb -A trust > /dev/null
    just start-db
    createdb rezible
    just run-migrations
    # just run-backend load-fake-config

@run-migrations:
    just run-backend migrate

@seed-db:
    just run-backend seed

@start-db:
    -pg_isready -q || pg_ctl -o "-k $PGHOST" start > /dev/null

@run-psql:
    psql -d rezible

@stop-db:
    -pg_isready -q && pg_ctl stop > /dev/null
