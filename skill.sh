#!/bin/bash

# WHOOP Skill Wrapper
# Provides CLI access to WHOOP data

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SKILL_DIR/.whoop_config.json"
CREDS_FILE="$SKILL_DIR/.whoop_tokens.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Load config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        CLIENT_ID=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['client_id'])")
        CLIENT_SECRET=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['client_secret'])")
        # Use config URLs or default to production
        AUTH_URL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('auth_url', 'https://api.prod.whoop.com/oauth/oauth2/auth'))")
        TOKEN_URL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('token_url', 'https://api.prod.whoop.com/oauth/oauth2/token'))")
        REDIRECT_URI=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['redirect_uri'])")
    else
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi
}

# Check if response is valid JSON with access_token
is_valid_token_response() {
    echo "$1" | python3 -c "import sys, json; d=json.load(sys.stdin); sys.exit(0 if 'access_token' in d else 1)" 2>/dev/null
}

# Get access token (refresh if needed)
get_token() {
    load_config
    
    if [ ! -f "$CREDS_FILE" ]; then
        log_error "Not authenticated. Run 'whoop auth' first."
        exit 1
    fi
    
    # Check if refresh needed
    EXPIRY=$(python3 -c "import json; t=json.load(open('$CREDS_FILE')); print(t.get('expires_at', 0))" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    
    if [ "$EXPIRY" -lt "$NOW" ]; then
        log_info "Refreshing token..."
        REFRESH_TOKEN=$(python3 -c "import json; print(json.load(open('$CREDS_FILE'))['refresh_token'])" 2>/dev/null)
        
        if [ -z "$REFRESH_TOKEN" ]; then
            log_error "No refresh token found. Run 'whoop auth' again."
            exit 1
        fi
        
        # Use stdin to avoid exposing secrets in process list
        RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "grant_type=refresh_token" \
            --data-urlencode "client_id=$CLIENT_ID" \
            --data-urlencode "client_secret=$CLIENT_SECRET" \
            --data-urlencode "refresh_token=$REFRESH_TOKEN")
        
        # Check if valid response before saving
        if is_valid_token_response "$RESPONSE"; then
            EXPIRY=$(python3 -c "import json; import time; t=json.loads('''$RESPONSE'''); print(int(time.time()) + t.get('expires_in', 3600))")
            echo "$RESPONSE" | python3 -c "import json, sys; t=json.load(sys.stdin); t['expires_at']=$EXPIRY; print(json.dumps(t))" > "$CREDS_FILE"
            log_info "Token refreshed."
        else
            log_error "Token refresh failed. Response: $RESPONSE"
            exit 1
        fi
    fi
    
    ACCESS_TOKEN=$(python3 -c "import json; print(json.load(open('$CREDS_FILE'))['access_token'])")
    echo "$ACCESS_TOKEN"
}

# Generate ISO 8601 timestamp using Python for portability
get_timestamp() {
    local days=${1:-0}
    python3 -c "from datetime import datetime, timedelta; d = datetime.now() - timedelta(days=$days); print(d.strftime('%Y-%m-%dT%H:%M:%SZ'))"
}

# --- Commands ---

cmd_auth() {
    log_info "Starting WHOOP OAuth flow..."
    load_config
    
    # Generate secure state parameter (required by Whoop, min 8 chars)
    STATE=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
    
    AUTH_URL_WITH_PARAMS="${AUTH_URL}?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=read:recovery+read:cycles+read:workout+read:sleep+read:profile+offline&state=${STATE}"
    
    echo ""
    echo "1. Visit this URL in your browser:"
    echo "$AUTH_URL_WITH_PARAMS"
    echo ""
    echo "2. After authorizing, you'll be redirected to:"
    echo "$REDIRECT_URI?code=XXXXX&state=$STATE"
    echo ""
    echo "3. Copy the full redirect URL and paste it below."
    echo ""
    read -p "Paste redirect URL: " REDIRECT_URL
    
    # Use Python to extract code and state from URL
    CODE=$(python3 -c "from urllib.parse import urlparse, parse_qs; print(parse_qs(urlparse('$REDIRECT_URL').query)['code'][0])" 2>/dev/null)
    RESPONSE_STATE=$(python3 -c "from urllib.parse import urlparse, parse_qs; print(parse_qs(urlparse('$REDIRECT_URL').query).get('state', [''])[0])" 2>/dev/null)
    
    # Validate state parameter
    if [ "$RESPONSE_STATE" != "$STATE" ]; then
        log_error "State mismatch! Expected: $STATE, Got: $RESPONSE_STATE"
        exit 1
    fi
    
    if [ -z "$CODE" ]; then
        log_error "Could not extract code from URL"
        exit 1
    fi
    
    log_info "Exchanging code for tokens..."
    
    # Use stdin for secrets
    RESPONSE=$(echo "grant_type=authorization_code&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&redirect_uri=$REDIRECT_URI&code=$CODE" | curl -s -X POST "$TOKEN_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "grant_type=authorization_code" \
        --data-urlencode "client_id=$CLIENT_ID" \
        --data-urlencode "client_secret=$CLIENT_SECRET" \
        --data-urlencode "redirect_uri=$REDIRECT_URI" \
        --data-urlencode "code=$CODE")
    
    # Check if valid response before saving
    if is_valid_token_response "$RESPONSE"; then
        EXPIRY=$(python3 -c "import json; import time; t=json.loads('''$RESPONSE'''); print(int(time.time()) + t.get('expires_in', 3600))")
        echo "$RESPONSE" | python3 -c "import json, sys; t=json.load(sys.stdin); t['expires_at']=$EXPIRY; print(json.dumps(t))" > "$CREDS_FILE"
        log_info "Success! Tokens saved to $CREDS_FILE"
    else
        log_error "Token exchange failed. Response: $RESPONSE"
        exit 1
    fi
}

cmd_recovery() {
    local days=${1:-7}
    log_info "Fetching recovery data for last $days days..."
    
    TOKEN=$(get_token)
    
    END=$(get_timestamp 0)
    START=$(get_timestamp "$days")
    
    RESPONSE=$(curl -s -X GET "https://api.prod.whoop.com/developer/v2/recovery?start=$START&end=$END" \
        -H "Authorization: Bearer $TOKEN")
    
    # Check if response is valid JSON
    if ! echo "$RESPONSE" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        log_error "API request failed. Response: $RESPONSE"
        exit 1
    fi
    
    echo "$RESPONSE" | python3 -c "
import json, sys

data = json.load(sys.stdin)
records = data.get('records', [])

for r in records:
    score = r.get('score', {})
    date = r.get('created_at', '').split('T')[0]
    recovery = score.get('recovery_score', 'N/A')
    hrv = score.get('hrv_rmssd_milli', 'N/A')
    rhr = score.get('resting_heart_rate', 'N/A')
    print(f'{date}: Recovery {recovery}% | HRV {hrv}ms | RHR {rhr}bpm')
"
}

cmd_sleep() {
    local days=${1:-7}
    log_info "Fetching sleep data for last $days days..."
    
    TOKEN=$(get_token)
    
    END=$(get_timestamp 0)
    START=$(get_timestamp "$days")
    
    RESPONSE=$(curl -s -X GET "https://api.prod.whoop.com/developer/v2/activity/sleep?start=$START&end=$END" \
        -H "Authorization: Bearer $TOKEN")
    
    # Check if response is valid JSON
    if ! echo "$RESPONSE" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        log_error "API request failed. Response: $RESPONSE"
        exit 1
    fi
    
    echo "$RESPONSE" | python3 -c "
import json, sys

data = json.load(sys.stdin)
records = data.get('records', [])

for r in records:
    score = r.get('score', {})
    date = r.get('start', '').split('T')[0]
    
    total_milli = score.get('stage_summary', {}).get('total_in_bed_time_milli', 0)
    hours = total_milli / 3600000
    
    perf = score.get('sleep_performance_percentage', 'N/A')
    eff = score.get('sleep_efficiency_percentage', 'N/A')
    print(f'{date}: {hours:.1f}h | Performance {perf}% | Efficiency {eff}%')
"
}

cmd_today() {
    log_info "Fetching today's summary..."
    
    TOKEN=$(get_token)
    
    END=$(get_timestamp 0)
    START=$(get_timestamp 1)
    
    # Get today's cycle
    RESPONSE=$(curl -s -X GET "https://api.prod.whoop.com/developer/v1/cycle?start=$START&end=$END" \
        -H "Authorization: Bearer $TOKEN")
    
    # Check if response is valid JSON
    if ! echo "$RESPONSE" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
        log_error "API request failed. Response: $RESPONSE"
        exit 1
    fi
    
    echo "$RESPONSE" | python3 -c "
import json, sys

data = json.load(sys.stdin)
records = data.get('records', [])

if records:
    c = records[0]
    score = c.get('score', {})
    date = c.get('start', '').split('T')[0]
    
    print(f'--- Today ({date}) ---')
    print(f'Strain: {score.get(\"strain\", \"N/A\")}')
    print(f'Avg HR: {score.get(\"average_heart_rate\", \"N/A\")} bpm')
    print(f'Max HR: {score.get(\"max_heart_rate\", \"N/A\")} bpm')
    print(f'kJ: {score.get(\"kilojoule\", \"N/A\")}')
else:
    print('No cycle data for today yet.')
"
}

cmd_help() {
    echo "WHOOP Skill CLI"
    echo ""
    echo "Usage: whoop <command> [args]"
    echo ""
    echo "Commands:"
    echo "  auth           Authenticate with WHOOP (OAuth)"
    echo "  recovery [N]   Show recovery scores for last N days (default 7)"
    echo "  sleep [N]      Show sleep data for last N days (default 7)"
    echo "  today          Show today's Strain summary"
    echo ""
}

# Main Dispatcher
case "$1" in
    auth) cmd_auth ;;
    recovery) cmd_recovery "$2" ;;
    sleep) cmd_sleep "$2" ;;
    today) cmd_today ;;
    help|*) cmd_help ;;
esac
