.PHONY: lint
lint: vendor
	docker run --rm -v $(CURDIR):/app -w /app golangci/golangci-lint:latest golangci-lint run -c .golangci.yaml

.PHONY: test
test: vendor
	go test ./...

vendor: go.mod go.sum
	go mod tidy
	go mod vendor

.PHONY: build
build:
	go build -o bumper

.PHONY: clean
clean:
	rm bumper
	rm -rf vendor