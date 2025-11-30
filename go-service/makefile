DB_DIR=../go-service-db
AUTH_DIR=../keycloak-service

generate-env:
	@./generate.sh

gen-server:
	rm -rf internal/api/client/generated
	mkdir -p internal/api/client/generated
	docker build -f internal/api/client/Dockerfile -t gen .
	docker run --rm -v $(PWD)/internal/api/client/generated:/internal/api/client/generated gen

setup-realm:
	@echo "Setting up Keycloak realm..."
	cd $(AUTH_DIR) && ./setup-keycloak-realm.sh


auth-up:
	cd $(AUTH_DIR) && docker compose --env-file $(PWD)/.env up -d

auth-down:
	cd $(AUTH_DIR) && docker compose --env-file $(PWD)/.env down

db-up: 
# generate-env
	cd $(DB_DIR) && docker compose --env-file $(PWD)/.env up -d

db-down:
	cd $(DB_DIR) && docker compose down	

db-clean:
	cd $(DB_DIR) && docker compose down -v
	sudo rm -rf $(DB_DIR)/data

run: 
	go run ./cmd/server/main.go

reset-keycloak-db:
	docker stop keycloak keycloak-postgres || true
	docker rm keycloak-postgres || true
	docker volume rm keycloak-service_keycloak-postgres-data || true
# 	docker compose up -d
