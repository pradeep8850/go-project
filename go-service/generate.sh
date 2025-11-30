#!/bin/bash
# generate-env.sh
# Generates .env file for MariaDB + Keycloak + PostgreSQL

ENV_FILE=".env"

# Backup existing .env if exists
if [ -f "$ENV_FILE" ]; then
    TIMESTAMP=$(date +%s)
    BACKUP_FILE=".env_$TIMESTAMP"
    mv "$ENV_FILE" "$BACKUP_FILE"
    echo "Existing .env file backed up as $BACKUP_FILE"
fi

# Generate random 16-character passwords
DB_PASS=$(openssl rand -hex 8)
POSTGRES_PASSWORD=$(openssl rand -hex 8)
KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -hex 8)

# Default MariaDB values
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="jobDb"
DB_USER="jobUser"

# Default Keycloak & Postgres values
KEYCLOAK_CONTAINER_NAME="jobqueue-keycloak"
POSTGRES_CONTAINER_NAME="keycloak-postgres"
POSTGRES_DB="keycloak"
POSTGRES_USER="keycloak"
POSTGRES_HOST="postgres"
POSTGRES_PORT="5432"
KEYCLOAK_PORT="8081"
KEYCLOAK_ADMIN="admin"

# Write variables to .env
cat <<EOF > "$ENV_FILE"
# ==========================
# MariaDB Configuration
# ==========================
MARIADB_ROOT_PASSWORD=$DB_PASS
MYSQL_ROOT_PASSWORD=$DB_PASS
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DB_NAME=$DB_NAME

# ==========================
# Keycloak + PostgreSQL Configuration
# ==========================
KEYCLOAK_CONTAINER_NAME=$KEYCLOAK_CONTAINER_NAME
POSTGRES_CONTAINER_NAME=$POSTGRES_CONTAINER_NAME

# Keycloak settings
KEYCLOAK_ADMIN=$KEYCLOAK_ADMIN
KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD
KEYCLOAK_PORT=$KEYCLOAK_PORT

# PostgreSQL settings
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST=$POSTGRES_HOST
POSTGRES_PORT=$POSTGRES_PORT

EOF

echo ".env file created successfully."
echo "--------------------------------------"
echo "MariaDB root password: $DB_PASS"
echo "Postgres password:     $POSTGRES_PASSWORD"
echo "Keycloak admin user:   $KEYCLOAK_ADMIN"
echo "Keycloak admin pass:   $KEYCLOAK_ADMIN_PASSWORD"
echo "--------------------------------------"
