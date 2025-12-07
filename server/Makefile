.PHONY: run build test tidy

# Load vars from .env if present when using `make run`
ifdef ENV
  export $(ENV)
endif

run:
	@echo "Starting server on :8080"
	@# Export variables from .env if present, then run
	@if [ -f .env ]; then \
		env $$(xargs < .env) go run ./cmd/server; \
	else \
		go run ./cmd/server; \
	fi

build:
	@mkdir -p bin
	go build -o bin/server ./cmd/server

test:
	go test ./...

tidy:
	go mod tidy

