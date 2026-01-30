# WHOOP Skill

This skill provides access to WHOOP fitness data, including Recovery, Sleep, Strain, and Workouts.

## Setup

1. **Register an App**: Go to the [WHOOP Developer Dashboard](https://developer-dashboard.whoop.com/) and create a new application.
2. **Get Credentials**: Note your `client_id` and `client_secret`.
3. **Set Redirect URI**: Set your redirect URI (e.g., `http://localhost:9876/callback`).
4. **Authenticate**: Run the `whoop auth` command to initiate the OAuth flow.

## Authentication

You must authenticate with WHOOP before using the skill. The skill uses OAuth 2.0.

```bash
# Authenticate - visit the URL and paste the redirect URL
whoop auth
```

## Configuration

Store your credentials in `.whoop_config.json` in the skill directory:

```json
{
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET",
  "redirect_uri": "http://localhost:9876/callback",
  "auth_url": "https://api.prod.whoop.com/oauth/oauth2/auth",
  "token_url": "https://api.prod.whoop.com/oauth/oauth2/token"
}
```

The skill looks for the config file in:
- `$SKILL_DIR/.whoop_config.json`

## Commands

- `whoop recovery [days]` - Get recovery scores for the last N days (default: 7)
- `whoop sleep [days]` - Get sleep data for the last N days (default: 7)
- `whoop today` - Get today's summary (Strain, HR, kJ)

## Data Endpoints

The WHOOP API provides access to:

- **Cycles**: Daily physiological cycles containing Strain and Sleep data
- **Recovery**: Recovery score, HRV, resting heart rate, SpO2, skin temp
- **Sleep**: Sleep stages (Light, REM, SWS), efficiency, performance
- **Workouts**: Individual workout sessions with Strain and heart rate data

## Rate Limits

- **Default**: 100 requests/minute, 10,000 requests/day
- Increases available upon request via WHOOP Developer Dashboard

## Dependencies

- **Python 3**: Required for JSON parsing and URL handling
- **curl**: For HTTP requests

No external Python packages required.
