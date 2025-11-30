#!/bin/bash
set -e

# Generate types
oapi-codegen --config /internal/api/client/oapi-codegen-types.cfg.yml /internal/api/client/openapi.yaml

# Generate server
oapi-codegen --config /internal/api/client/oapi-codegen-server.cfg.yml /internal/api/client/openapi.yaml

# Generate client
oapi-codegen --config /internal/api/client/oapi-codegen-client.cfg.yml /internal/api/client/openapi.yaml
