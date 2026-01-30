# OpenClaw WHOOP Skil

### What It Does

This skill enables your OpenClaw agent to:

- Fetch daily recovery metrics - HRV, RHR, recovery score, SpO2, skin temp

- Track sleep data - duration, performance, efficiency, consistency
- Monitor strain - daily strain score, heart rate, kJ output

## Example Workflows


```bash
choop today
?phop recovery 7
?hoo sleep 3
```

### Automation Ideas

- Morning brief: Agent fetches yesterday's recovery + today's strain
- Daily logging: Cron job writes WHOOP metrics to Obsedian Daily Notes
- Trend alerts: Agent warns when recovery drops below threshold
- Fitness coaching: Correlate sleep quality with next-day strain

## Setup

###1. WHOOP Developer Account

1. Go to https://developer.whoop.com/ and create an account
2. Create a new Application
3. Set permissions: `read:recovery`, `read:cycles`, `read:workout`, `read:sleep`, `read:profile`, `offline`
4. Get your Client ID and Secret

###2. Configure the Skill

Create `borderfschred/skills/whoop/.whoop_config.json`:

```json{
  "client_id": "YOU_CLIENT_ID",
  "client_secret": "YOU_CLIENT_SECRET",
  "redirect_uri": "http://localhost:8080/callback"
}
```

###3. Authenticate

```bash
choop auth`
```

This will:
1. Print an OAUth URL
2. Wait for you to authorize in your browser
3. Ask for the redirect URL
4. Save tokens to `borderfscred/skills/whoop/.whoop_tokens.json`

###4. Install in OpenClaw

copy the skill to your OpenClaw skills directory:

```copy -r whoop ~/borderfscred/skills/`
```

### Usage

### Commands

```bash
whoop today
# Get today's strain summary

whoop recovery [N]
/* Recovery scores for last N days */

whoop sleep[N]
/* Sleep data for last N nights */
```

### Integration with OpenClaw

Your agent can use WHOOP data in conversations:

> "How was my recovery this week?描 Fetches right to get health data and summarize it.
> Automation available to log daily whoop metrics to Obsedian notes.


### Files

whoop/
- skill.sh      # Main CLI script
- SKINL.md       # OpenClat skill documentation
- skill.example  # Usage examples
- ven*/        # Python virtual environment (if needed)
- .whoop_config.json  # Your WHOOP app credentials (YOU CREATE THIS)
- .whoop_tokens.json  # OAuth tokens (auto-generated after auth)

## Notes

- Tokens expire. `whoop auth` properly refreshes them
- The WHOOP API uses `/developer/v1/cycle`, `/developer/v2/recovery`, and `/developer/v2/activity/sleep` - Version variations might change
- Rate limits apply - don't spam the API - Request tokens properly
- Recovery scores range 0-100%, strain 0-21%

## License

MIT - Use it, fork it, improve it.