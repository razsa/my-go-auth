include .env

# Default to podman, but allow override with CONTAINER_RUNTIME
CONTAINER_RUNTIME ?= podman

ifeq ($(CONTAINER_RUNTIME),docker)
	CONTAINER_CMD := docker
else
	CONTAINER_CMD := podman
endif

stop_container:
	@echo "Stopping database container"
	@if [ $$($(CONTAINER_CMD) ps -q) ]; then \
		echo "Found and stopped containers"; \
		$(CONTAINER_CMD) stop $$($(CONTAINER_CMD) ps -q); \
	else \
		echo "No containers running..."; \
	fi

create_container:
	$(CONTAINER_CMD) run --name ${DB_PODMAN_CONTAINER} -p 3306:3306 \
		-e MARIADB_USER=${USER} \
		-e MARIADB_PASSWORD=${PASSWORD} \
		-e MARIADB_DATABASE=${DB_NAME} \
		-e MARIADB_ROOT_PASSWORD=${ROOT_PASSWORD} \
		-d mariadb:latest

create_db:
	@echo "Database is created automatically with MariaDB container."

start_container:
	$(CONTAINER_CMD) start ${DB_PODMAN_CONTAINER}

migrate_up:
	@echo "Running database migrations..."
	GOOSE_DRIVER=mysql GOOSE_DBSTRING="${USER}:${PASSWORD}@tcp(localhost:3306)/${DB_NAME}" goose -dir sql/schema up

migrate_down:
	@echo "Rolling back last database migration..."
	GOOSE_DRIVER=mysql GOOSE_DBSTRING="${USER}:${PASSWORD}@tcp(localhost:3306)/${DB_NAME}" goose -dir sql/schema down

build:
	if [ -f "${BINARY}" ]; then \
		rm "${BINARY}"; \
		echo "Deleted ${BINARY}"; \
	fi
	@echo "Building ${BINARY}"
	go build -o ${BINARY} main.go

run: build
	@echo "Running ${BINARY}"
	./${BINARY}

stop:
	@echo "Stopping server..."
	@-pkill -SIGTERM -f "./${BINARY}"
	@echo "Server stopped..."

# Help target to show available options
help:
	@echo "Available targets:"
	@echo "  stop_container    - Stop running database container"
	@echo "  create_container  - Create a new database container"
	@echo "  start_container   - Start the database container"
	@echo "  migrate_up        - Run database migrations"
	@echo "  migrate_down      - Rollback database migrations"
	@echo "  build             - Build the application"
	@echo "  run               - Build and run the application"
	@echo "  stop              - Stop the application"
	@echo ""
	@echo "Container Runtime Options:"
	@echo "  Default is podman. Use CONTAINER_RUNTIME=docker to use Docker instead."
	@echo "  Example: make create_container CONTAINER_RUNTIME=docker"
