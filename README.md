# message-action

Send GitHub Actions notifications to Telegram or ntfy.

## Usage

```yaml
- uses: gbraad-dotfiles/message-action@main
  if: always()
  with:
    status: ${{ job.status }}
    message: "Deploy to production finished"
  env:
    TELEGRAM_TOKEN: ${{ secrets.TELEGRAM_TOKEN }}
    TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

The backend is auto-detected from available credentials. Both Telegram and ntfy can fire simultaneously.

---

## Telegram setup

### 1. Create a bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot`
3. Choose a display name (e.g. `My Notifications`)
4. Choose a username ending in `_bot` (e.g. `mynotifs_bot`)
5. BotFather replies with your *bot token*. Save it as `TELEGRAM_TOKEN`

### 2. Create a private group

1. Tap the pencil/compose icon → *New Group*
2. In the member search, type your bot's username (e.g. `@mynotifs_bot`) and add it
3. Give the group any name (e.g. `notifications`). This is just a display name, not a public link
4. *Do not* set a public username or invite link. This way the group stays private

### 3. Get the chat ID

Send any message in the group, then run:

```sh
curl "https://api.telegram.org/bot<TOKEN>/getUpdates" | python3 -m json.tool
```

Look for:

```json
"chat": {
  "id": -1234567890,
  "title": "notifications",
  "type": "group"
}
```

The `id` value (a negative number) is your `TELEGRAM_CHAT_ID`.

> If `getUpdates` returns empty, a webhook may be set. Clear it first:
> ```sh
> curl "https://api.telegram.org/bot<TOKEN>/deleteWebhook"
> ```
> Then send another message in the group and try again.

### 4. Add secrets to GitHub

In your repository: *Settings* → Secrets and variables → Actions → New repository secret

| Name | Value |
|------|-------|
| `TELEGRAM_TOKEN` | The bot token from BotFather |
| `TELEGRAM_CHAT_ID` | The negative group ID from getUpdates |

---

## ntfy setup

No account or bot needed.

1. Pick a secret topic name (e.g. `myrepo-ci-abc123`)
2. Subscribe in the [ntfy app](https://ntfy.sh) or at `https://ntfy.sh/your-topic`
3. Set `NTFY_URL` secret to `https://ntfy.sh/your-topic` (or your self-hosted URL)

```yaml
  env:
    NTFY_URL: ${{ secrets.NTFY_URL }}
```

---

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `message` | Message body | yes |
| `title` | Message title (defaults to workflow name) | no |
| `status` | `success`, `failure`, or `cancelled` | no |
| `telegram_token` | Telegram bot token | no |
| `telegram_chat_id` | Telegram chat/group ID | no |
| `ntfy_url` | Full ntfy topic URL | no |

Credentials can also be passed via environment variables/secrets instead of inputs.

