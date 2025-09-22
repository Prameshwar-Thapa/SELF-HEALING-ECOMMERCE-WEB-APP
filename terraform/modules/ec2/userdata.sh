#!/bin/bash
# E-commerce backend bootstrap (Amazon Linux 2023)
set -euo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

###################### CONFIG ######################
REGION="${REGION}"
ARTIFACT_S3="${ARTIFACT_S3}"
DB_HOST="${DB_HOST}"
APP_PORT="3000"
HOST_BIND="0.0.0.0"
JWT_EXPIRES_IN="24h"

# Secrets Manager names
SM_DB_SECRET="${DB_SECRET_NAME}"
SM_CFG_SECRET="${APP_CONFIG_SECRET_NAME}"
SM_JWT_SECRET="${JWT_SECRET_NAME}"
####################################################################

echo "[user-data] Installing packages (excluding curl to avoid conflicts)"
# AL2023 already includes curl-minimal. Avoid installing curl to prevent conflicts.
dnf -y install unzip nodejs npm awscli jq rsync --exclude=curl --exclude=curl-minimal >/dev/null

# Verify curl availability (curl-minimal is fine)
if ! command -v curl >/dev/null 2>&1; then
  echo "[user-data] WARNING: curl not found; health probes will be skipped"
  CURL_OK=0
else
  CURL_OK=1
fi

APP_ROOT="/opt/ecommerce-app"
BACKEND_DIR="$APP_ROOT/backend"
LOG_DIR="$APP_ROOT/logs"
TMP_ZIP="/tmp/backend.zip"

echo "[user-data] Prepping directories"
rm -rf "$BACKEND_DIR"
mkdir -p "$BACKEND_DIR" "$LOG_DIR"
chown -R ec2-user:ec2-user "$APP_ROOT"

echo "[user-data] Downloading artifact: $ARTIFACT_S3"
for i in {1..5}; do
  if aws s3 cp "$ARTIFACT_S3" "$TMP_ZIP" --region "$REGION"; then
    break
  fi
  echo "[user-data] S3 download attempt $i failed; retrying in 5s..."
  sleep 5
done
test -s "$TMP_ZIP" || { echo "[user-data][ERROR] Artifact not found or empty at $ARTIFACT_S3"; exit 1; }

echo "[user-data] Unpacking artifact"
unzip -oq "$TMP_ZIP" -d "$BACKEND_DIR"

# Flatten if the zip has a top-level folder
if [ ! -f "$BACKEND_DIR/package.json" ]; then
  SUBDIR="$(find "$BACKEND_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
  if [ -n "$SUBDIR" ] && [ -f "$SUBDIR/package.json" ]; then
    echo "[user-data] Flattening $SUBDIR into $BACKEND_DIR"
    rsync -a "$SUBDIR/." "$BACKEND_DIR/"
    rm -rf "$SUBDIR"
  fi
fi

# Hard checks
test -f "$BACKEND_DIR/package.json" || { echo "[user-data][ERROR] package.json missing in artifact"; exit 2; }
test -f "$BACKEND_DIR/server.js"    || { echo "[user-data][ERROR] server.js missing in artifact"; exit 3; }

echo "[user-data] Installing Node dependencies (production)"
cd "$BACKEND_DIR"
if [ -f package-lock.json ]; then
  npm ci --omit=dev || npm ci
else
  npm install --omit=dev || npm install
fi

# Helper: read a Secrets Manager string (raw or JSON)
get_secret_string () {
  aws secretsmanager get-secret-value \
    --secret-id "$1" \
    --query SecretString \
    --output text \
    --region "$REGION" 2>/dev/null || true
}

# ---- Database secret ----
echo "[user-data] Fetching DB secret: $SM_DB_SECRET"
DB_RAW="$(get_secret_string "$SM_DB_SECRET")"
[ -n "$$${DB_RAW:-}" ] || { echo "[user-data][ERROR] Failed to read DB secret"; exit 4; }

if echo "$DB_RAW" | jq -e . >/dev/null 2>&1; then
  DB_USER="$(echo "$DB_RAW" | jq -r '.username // .user // .DB_USER // empty')"
  DB_PASSWORD="$(echo "$DB_RAW" | jq -r '.password // .DB_PASSWORD // .db_password // empty')"
  DB_NAME="$(echo "$DB_RAW" | jq -r '.dbname // .db_name // .DB_NAME // empty')"
else
  # raw string fallback: treat as password only
  DB_USER=""
  DB_NAME=""
  DB_PASSWORD="$DB_RAW"
fi
[ -n "$${DB_PASSWORD:-}" ] || { echo "[user-data][ERROR] DB password missing in secret"; exit 4; }

# ---- App config secret (CORS, optional DB_USER/DB_NAME overrides) ----
echo "[user-data] Fetching config secret: $SM_CFG_SECRET"
CFG_RAW="$(get_secret_string "$SM_CFG_SECRET")"
CLOUDFRONT_URL=""
API_ALLOWED_ORIGINS=""
if [ -n "$${CFG_RAW:-}" ]; then
  if echo "$CFG_RAW" | jq -e . >/dev/null 2>&1; then
    CLOUDFRONT_URL="$(echo "$CFG_RAW" | jq -r '.CLOUDFRONT_URL // .cloudfront_url // empty')"
    API_ALLOWED_ORIGINS="$(echo "$CFG_RAW" | jq -r '.ALLOWED_ORIGINS // .allowed_origins // empty')"
    # Fill DB_USER/DB_NAME if provided here and missing above
    if [ -z "$${DB_USER}" ]; then DB_USER="$(echo "$CFG_RAW" | jq -r '.DB_USER // empty')"; fi
    if [ -z "$${DB_NAME}" ]; then DB_NAME="$(echo "$CFG_RAW" | jq -r '.DB_NAME // empty')"; fi
  else
    case "$CFG_RAW" in http://*|https://*) CLOUDFRONT_URL="$CFG_RAW" ;; esac
  fi
fi
DB_USER="$${DB_USER:-ecommerceadmin}"
DB_NAME="$${DB_NAME:-ecommerce_db}"

# ---- JWT secret ----
echo "[user-data] Fetching JWT secret: $SM_JWT_SECRET"
JWT_RAW="$(get_secret_string "$SM_JWT_SECRET")"
[ -n "$${JWT_RAW:-}" ] || { echo "[user-data][ERROR] Failed to read JWT secret"; exit 5; }
if echo "$JWT_RAW" | jq -e . >/dev/null 2>&1; then
  JWT_SECRET_VAL="$(echo "$JWT_RAW" | jq -r '.JWT_SECRET // .jwt // .jwt_secret // empty')"
else
  JWT_SECRET_VAL="$JWT_RAW"
fi
[ -n "$${JWT_SECRET_VAL:-}" ] || { echo "[user-data][ERROR] JWT secret value missing"; exit 5; }

echo "[user-data] Writing .env"
umask 077
cat >"$BACKEND_DIR/.env" <<EOF
NODE_ENV=production
HOST=$${HOST_BIND}
PORT=$${APP_PORT}

# --- RDS/MySQL ---
DB_HOST=${DB_HOST}
DB_PORT=3306
DB_NAME=$${DB_NAME}
DB_USER=$${DB_USER}
DB_PASSWORD=$${DB_PASSWORD}

# --- Security / JWT ---
JWT_SECRET=$${JWT_SECRET_VAL}
JWT_EXPIRES_IN=$${JWT_EXPIRES_IN}

# --- CORS allowed origins ---
CLOUDFRONT_URL=$${CLOUDFRONT_URL}
ALLOWED_ORIGINS=$${API_ALLOWED_ORIGINS}

# --- Logging & Region ---
LOG_LEVEL=info
AWS_REGION=${REGION}
AWS_DEFAULT_REGION=${REGION}

# --- App behavior ---
REQUIRE_DB=true
EOF
chown ec2-user:ec2-user "$BACKEND_DIR/.env"
chmod 600 "$BACKEND_DIR/.env"

echo "[user-data] Creating systemd unit"
cat >/etc/systemd/system/ecommerce-backend.service <<'EOF'
[Unit]
Description=E-commerce Backend API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/ecommerce-app/backend
EnvironmentFile=/opt/ecommerce-app/backend/.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ecommerce-backend

[Install]
WantedBy=multi-user.target
EOF

echo "[user-data] Enabling & starting service"
systemctl daemon-reload
systemctl enable ecommerce-backend
systemctl start ecommerce-backend

if [ "$CURL_OK" -eq 1 ]; then
  echo "[user-data] Probing health with retries"
  for i in {1..20}; do
    if curl -sf "http://127.0.0.1:$${APP_PORT}/health" >/dev/null || \
       curl -sf "http://127.0.0.1:$${APP_PORT}/live"   >/dev/null; then
      echo "[user-data] App is healthy"
      break
    fi
    echo "[user-data] Waiting for app to become healthy... ($i/20)"
    sleep 3
  done
else
  echo "[user-data] Skipping curl-based health probe"
fi

echo "[user-data] Completed successfully"

----
