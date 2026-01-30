# OpenClaw WHOOP Skill

A CLI skill for OpenClaw that integrates WHOOP health & fitness data into your autonomous agent workflow.

## What It Does

This skill enables your OpenClaw agent to:

- Fetch daily recovery metrics — HRV, RHR, recovery score, SpO2, skin temp
- Track sleep data — duration, performance, efficiency, consistency
- Monitor strain — daily strain score, heart rate, kJ output
- Auto-log to Obsidian — daily metrics written to your notes
- Weekly analysis — correlation between recovery, sleep, and strain

## Example Workflows

```bash
# Get today's strain
whoop today

# Last 7 days recovery
whoop recovery 7

# Last 3 nights sleep
whoop sleep 3
```

### Automation Ideas

- Morning brief: Agent fetches yesterday's recovery + today's strain
- Daily logging: Cron job writes WHOOP metrics to Obsidian Daily Notes
- Trend alerts: Agent warns when recovery drops below threshold
- Fitness coaching: Correlate sleep quality with next-day strain

## Setup

### 1. WHOOP Developer Account

1. Go to https://developer.whoop.com/ and create an account
2. Create a new Application
3. Set permissions: `read:recovery`, `read:cycles`, `read:workout`, `read:sleep`, `read:profile`, `offline`
4. Get your Client ID and Secret

### 2. Configure the Skill

Create `~/.clawdbot/skills/whoop/.whoop_config.json`:

```json
{
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET",
  "redirect_uri": "http://localhost:8080/callback"
}
```

### 3. Authenticate

```bash
# Run the auth command
whoop auth

# This will:
# 1. Print an OAuth URL
# 2. Wait for you to authorize in your browser
# 3. Ask for the redirect URL
# 4. Save tokens to ~/.clawdbot/skills/whoop/.whoop_tokens.json
```

### 4. Install in OpenClaw

Copy the skill to your OpenClaw skills directory:

```bash
cp -r whoop ~/.clawdbot/skills/
```

Add to your `openclaw.json` skills configuration:

```json
{
  "skills": {
    "entries": {
      "whoop": {
        "enabled": true
      }
    }
  }
}
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `whoop today` | Today's strain summary |
| `whoop recovery [N]` | Recovery scores for last N days |
| `whoop sleep [N]` | Sleep data for last N nights |
| `whoop auth` | Re-authenticate with WHOOP |

### Integration with OpenClaw

Your agent can use WHOOP data in conversations:

> "How was my recovery this week?"
> → Agent runs `whoop recovery 7` and summarizes

> "Log my sleep data to Obsidian"
> → Agent runs sleep command, formats for your template

## Files

```
whoop/
├── skill.sh        # Main CLI script
├── SKILL.md        # OpenClaw skill documentation
├── skill.example   # Usage examples
├── venv/           # Python virtual environment (if needed)
├── .whoop_config.json     # Your WHOOP app credentials (YOU CREATE THIS)
└── .whoop_tokens.json     # OAuth tokens (auto-generated after auth)
```

## Notes

- Tokens expire. `whoop auth` refreshes them automatically
- The WHOOP API uses `/developer/v1/cycle`, `/developer/v2/recovery`, and `/developer/v2/activity/sleep`
- Rate limits apply — don't spam the API
- Recovery scores range 0-100%, strain 0-21

## License

MIT — Use it, fork it, improve it.
