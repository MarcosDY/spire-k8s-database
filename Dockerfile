FROM golang:1.17-alpine as builder
RUN apk add build-base git

from alpine AS image-base 
RUN apk --no-cache add dumb-init curl vim git

# Build api service
FROM builder as service-builder
WORKDIR /service
COPY src/api/. .
RUN go mod download
RUN go build

FROM image-base AS api-service
RUN mkdir -p /opt/service
COPY --from=service-builder /service/api /opt/service/api
WORKDIR /opt/service/
ENTRYPOINT ["/usr/bin/dumb-init", "/opt/service/api"]
CMD []

# Build client service
FROM builder as client-builder
WORKDIR /client
COPY src/client/. .
RUN go mod download
RUN go build

FROM image-base AS client-service
RUN mkdir -p /opt/service
COPY --from=client-builder /client/client /opt/service/client
ENTRYPOINT ["/usr/bin/dumb-init", "/opt/service/client"]
CMD []

WORKDIR /opt/service/

# Build spiffe-helper
FROM builder as helper-builder
WORKDIR /service
RUN git clone -b upgrade-helper https://github.com/marcosdy/spiffe-helper.git .
RUN go build -o /service/spiffe-helper ./cmd/spiffe-helper

FROM image-base AS spiffe-helper
RUN addgroup -g 70 ssl-cert
RUN adduser -G ssl-cert -u 70 -D postgres

RUN apk add --no-cache --upgrade postgresql-client bash
COPY --from=helper-builder /service/spiffe-helper /opt/helper/spiffe-helper

WORKDIR /opt/helper/

