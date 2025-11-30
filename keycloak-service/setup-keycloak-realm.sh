#!/bin/bash

# Load environment variables from your .env file
# Be sure to adjust the path if necessary
ENV_FILE_PATH="../go-service/.env"
if [ -f "$ENV_FILE_PATH" ]; then
  set -a
  source "$ENV_FILE_PATH"
  set +a
else
  echo "Error: .env file not found at $ENV_FILE_PATH"
  exit 1
fi

# Script settings
KEYCLOAK_URL="http://localhost:${KEYCLOAK_PORT:-8080}"
REALM_NAME="${REALM_NAME:-myrealm}"

DEFAULT_USERNAME="${DEFAULT_USERNAME:-testuser}"
DEFAULT_EMAIL="${DEFAULT_EMAIL:-testuser@example.com}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD:-password123}"
DEFAULT_FIRSTNAME="${DEFAULT_FIRSTNAME:-Test}"
DEFAULT_LASTNAME="${DEFAULT_LASTNAME:-User}"

CLIENT_ID="admin-cli"

echo "=== Keycloak Realm Setup Script ==="
echo "Keycloak URL: $KEYCLOAK_URL"
echo "Realm Name: $REALM_NAME"
echo ""

# Step 1: Get admin access token
echo "Step 1: Logging in to Keycloak as $KEYCLOAK_ADMIN..."
TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$KEYCLOAK_ADMIN" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID")

ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | grep -oP '"access_token":"\K[^"]+')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to obtain access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "✓ Successfully logged in"
echo ""

# Step 2: Check if realm exists and delete it
echo "Step 2: Checking if realm '$REALM_NAME' exists..."
REALM_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$REALM_CHECK" = "200" ]; then
  echo "Realm '$REALM_NAME' exists. Deleting..."
  DELETE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  
  if [ "$DELETE_RESPONSE" = "204" ]; then
    echo "✓ Realm '$REALM_NAME' deleted successfully"
  else
    echo "Error: Failed to delete realm (HTTP $DELETE_RESPONSE)"
    exit 1
  fi
else
  echo "Realm '$REALM_NAME' does not exist. Skipping deletion."
fi
echo ""

# Step 3: Create new realm
echo "Step 3: Creating new realm '$REALM_NAME'..."
CREATE_REALM_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$KEYCLOAK_URL/admin/realms" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "'"$REALM_NAME"'",
    "enabled": true,
    "sslRequired": "external"
  }')

if [ "$CREATE_REALM_RESPONSE" = "201" ]; then
  echo "✓ Realm '$REALM_NAME' created successfully"
else
  echo "Error: Failed to create realm (HTTP $CREATE_REALM_RESPONSE)"
  exit 1
fi
echo ""

# Step 4: Create default user
echo "Step 4: Creating default user '$DEFAULT_USERNAME'..."

CREATE_USER_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'"$DEFAULT_USERNAME"'",
    "email": "'"$DEFAULT_EMAIL"'",
    "firstName": "'"$DEFAULT_FIRSTNAME"'",
    "lastName": "'"$DEFAULT_LASTNAME"'",
    "enabled": true,
    "emailVerified": true,
    "credentials": [{
      "type": "password",
      "value": "'"$DEFAULT_PASSWORD"'",
      "temporary": false
    }]
  }')

if [ "$CREATE_USER_RESPONSE" = "201" ]; then
  echo "✓ User '$DEFAULT_USERNAME' created successfully"
else
  echo "Error: Failed to create user (HTTP $CREATE_USER_RESPONSE)"
  exit 1
fi
echo ""

echo "=== Setup Complete ==="
echo "Realm: $REALM_NAME"
echo "User: $DEFAULT_USERNAME"
echo "Email: $DEFAULT_EMAIL"
echo "Password: $DEFAULT_PASSWORD"
echo ""

echo "You can now log in to Keycloak at: $KEYCLOAK_URL"
