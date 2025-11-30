FROM golang:1.24.3

RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

ENV CGO_ENABLED=0

RUN go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.5.0

COPY internal/api/client/ /internal/api/client/
WORKDIR /internal/api/client
RUN chmod +x generate.sh
CMD ["./generate.sh"]