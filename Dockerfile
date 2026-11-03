# Build
FROM golang:1.26-alpine AS build

RUN apk add --no-cache --update make \
    && rm -f /var/cache/apk/*

WORKDIR /go/src/app
ADD ./ /go/src/app

RUN make build

# Run
FROM alpine:3.23

RUN apk add --no-cache jq curl

COPY entrypoint.sh /entrypoint.sh
COPY --from=build /go/src/app/bumper /bumper

ENTRYPOINT ["/entrypoint.sh"]
