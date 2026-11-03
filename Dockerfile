# Build
FROM golang:1.26-alpine@sha256:a2012b4a1d1f9f7e9f44e0d39b805a901e856b1dd80b4e6ee4338db547050308 AS build

RUN apk add --no-cache --update make \
    && rm -f /var/cache/apk/*

WORKDIR /go/src/app
ADD ./ /go/src/app

RUN make build

# Run
FROM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

RUN apk add --no-cache jq curl

COPY entrypoint.sh /entrypoint.sh
COPY --from=build /go/src/app/bumper /bumper

ENTRYPOINT ["/entrypoint.sh"]
