#!/bin/bash
# setup-keycloak-realm.sh
# Deletes ALL realms except master, creates "job" realm with admin user

set -euo pipefail

# Path to your env file (change if needed)
ENV_FILE_PATH="../go-service/.env"

if [ -f "$ENV_FILE_PATH" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE_PATH"
  set +a
else
  echo "Error: .env file not found at $ENV_FILE_PATH"
  exit 1
fi

# --------- Config ----------
KEYCLOAK_URL="http://localhost:8080"
MASTER_REALM="master"
JOB_REALM="job"

# Admin credentials from .env (for master realm login)
ADMIN_USERNAME="${KEYCLOAK_ADMIN:-admin}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:?KEYCLOAK_ADMIN_PASSWORD not set}"

# Job realm admin user credentials (add these to your generate-env.sh)
JOB_ADMIN_USERNAME="${JOB_ADMIN_USERNAME:-jobadmin}"
JOB_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:?KEYCLOAK_ADMIN_PASSWORD not set}"
JOB_ADMIN_EMAIL="${JOB_ADMIN_EMAIL:-jobadmin@example.com}"
# -----------------------------------------

echo "Using Keycloak at: $KEYCLOAK_URL"
echo "Master admin: $ADMIN_USERNAME"
echo "Job realm admin: $JOB_ADMIN_USERNAME"

# Get master admin access token
echo "==> Getting master admin access token..."
echo "DEBUG URL: ${KEYCLOAK_URL}/realms/${MASTER_REALM}/protocol/openid-connect/token"
echo "DEBUG ADMIN_USERNAME=$ADMIN_USERNAME"
echo "DEBUG ADMIN_PASSWORD=$ADMIN_PASSWORD"
ACCESS_TOKEN=$(
  curl -sS \
    -d "client_id=admin-cli" \
    -d "username=${ADMIN_USERNAME}" \
    -d "password=admin" \
    -d "grant_type=password" \
    "${KEYCLOAK_URL}/realms/${MASTER_REALM}/protocol/openid-connect/token" \
    | jq -r '.access_token'
)

if [ -z "${ACCESS_TOKEN}" ] || [ "${ACCESS_TOKEN}" = "null" ]; then
  echo "Error: Failed to obtain master admin token."
  exit 1
fi

# Step 1: Delete ALL realms except master
echo "==> Deleting ALL realms except 'master'..."
REALMS=$(curl -sS -H "Authorization: Bearer ${ACCESS_TOKEN}" "${KEYCLOAK_URL}/admin/realms" | jq -r '.[].realm')

DELETED_COUNT=0
for REALM in $REALMS; do
  if [ "$REALM" != "master" ] && [ "$REALM" != "job" ]; then
    echo "  Deleting realm: $REALM"
    DELETE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      "${KEYCLOAK_URL}/admin/realms/${REALM}")
    
    if [ "$DELETE_CODE" = "204" ]; then
      ((DELETED_COUNT++))
    else
      echo "  Warning: Could not delete $REALM (HTTP $DELETE_CODE)"
    fi
  fi
done

echo "Deleted $DELETED_COUNT realms."

# Step 2: Delete 'job' realm if it exists (to ensure clean slate)
echo "==> Ensuring 'job' realm is clean..."
DELETE_JOB_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${KEYCLOAK_URL}/admin/realms/job" 2>/dev/null || echo "404")

if [ "$DELETE_JOB_CODE" = "204" ]; then
  echo "Existing 'job' realm deleted."
fi

# Step 3: Create 'job' realm
echo "==> Creating 'job' realm..."
CREATE_REALM_CODE=$(
  curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
          \"id\": \"${JOB_REALM}\",
          \"realm\": \"${JOB_REALM}\",
          \"enabled\": true,
          \"displayName\": \"Job Queue\",
          \"sslRequired\": \"external\",
          \"registrationAllowed\": false
        }" \
    "${KEYCLOAK_URL}/admin/realms"
)

if [ "${CREATE_REALM_CODE}" != "201" ]; then
  echo "Error: Failed to create 'job' realm. HTTP ${CREATE_REALM_CODE}"
  exit 1
fi

echo "'job' realm created successfully."

# Step 4: Create job realm admin user
echo "==> Creating admin user '${JOB_ADMIN_USERNAME}' in 'job' realm..."
CREATE_USER_CODE=$(
  curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
          \"username\": \"${JOB_ADMIN_USERNAME}\",
          \"email\": \"${JOB_ADMIN_EMAIL}\",
          \"enabled\": true,
          \"emailVerified\": true
        }" \
    "${KEYCLOAK_URL}/admin/realms/${JOB_REALM}/users"
)

if [ "${CREATE_USER_CODE}" != "201" ]; then
  echo "Error: Failed to create admin user. HTTP ${CREATE_USER_CODE}"
  exit 1
fi

# Get job admin user ID
JOB_ADMIN_ID=$(
  curl -sS \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "${KEYCLOAK_URL}/admin/realms/${JOB_REALM}/users?username=${JOB_ADMIN_USERNAME}" \
    | jq -r '.[0].id'
)

# Step 5: Set password for job admin
echo "==> Setting password for job admin user..."
curl -s -X PUT \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
        \"type\": \"password\",
        \"value\": \"${JOB_ADMIN_PASSWORD}\",
        \"temporary\": false
      }" \
  "${KEYCLOAK_URL}/admin/realms/${JOB_REALM}/users/${JOB_ADMIN_ID}/reset-password" \
  || echo "Warning: Password set failed"

# Step 6: Assign admin role to job admin user (composite realm-management role)
echo "==> Assigning admin roles to job admin user..."
REALM_MANAGEMENT_CLIENT="realm-management"
curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${KEYCLOAK_URL}/admin/realms/${JOB_REALM}/users/${JOB_ADMIN_ID}/role-mappings/realm/composite" \
  -d "[
    {
      \"id\": \"$(curl -s -H \"Authorization: Bearer ${ACCESS_TOKEN}\" \"${KEYCLOAK_URL}/admin/realms/${JOB_REALM}/clients?clientId=${REALM_MANAGEMENT_CLIENT}\" | jq -r '.[0].id')\", 
      \"name\": \"${REALM_MANAGEMENT_CLIENT}\"
    }
  ]"

echo "---------------------------------------------"
echo "Setup completed! You now have:"
echo "Realm:          job"
echo "Admin user:     $JOB_ADMIN_USERNAME"
echo "Admin password: $JOB_ADMIN_PASSWORD"
echo "Admin email:    $JOB_ADMIN_EMAIL"
echo "---------------------------------------------"
