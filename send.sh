#!/usr/bin/env bash
set -euo pipefail

# Status emoji
status_emoji() {
  case "${MSG_STATUS:-}" in
    success)   echo "✅" ;;
    failure)   echo "❌" ;;
    cancelled) echo "⚠️" ;;
    *)         echo "📣" ;;
  esac
}

EMOJI=$(status_emoji)
TITLE="${MSG_TITLE:-${GH_WORKFLOW:-Notification}}"
MESSAGE="${MSG_MESSAGE:-}"
REPO="${GH_REPO:-}"
RUN_URL="${GH_RUN_URL:-}"

# Build full message
if [[ -n "$REPO" ]]; then
  FULL_MESSAGE="${EMOJI} *${TITLE}*
Repo: \`${REPO}\`
${MESSAGE}"
  if [[ -n "$RUN_URL" ]]; then
    FULL_MESSAGE="${FULL_MESSAGE}
[View run](${RUN_URL})"
  fi
else
  FULL_MESSAGE="${EMOJI} *${TITLE}*
${MESSAGE}"
fi

sent=0

# --- Telegram ---
if [[ -n "${TELEGRAM_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "Sending via Telegram..."
  response=$(curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "parse_mode=Markdown" \
    --data-urlencode "text=${FULL_MESSAGE}")
  if echo "$response" | grep -q '"ok":true'; then
    echo "Telegram: sent"
    sent=1
  else
    echo "Telegram: failed — $response" >&2
  fi
fi

# --- ntfy ---
if [[ -n "${NTFY_URL:-}" ]]; then
  echo "Sending via ntfy..."
  status_tag="${MSG_STATUS:-info}"
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Title: ${EMOJI} ${TITLE}" \
    -H "Tags: ${status_tag}" \
    ${RUN_URL:+-H "Click: ${RUN_URL}"} \
    -d "${MESSAGE}" \
    "${NTFY_URL}")
  if [[ "$response" == "200" ]]; then
    echo "ntfy: sent"
    sent=1
  else
    echo "ntfy: failed — HTTP ${response}" >&2
  fi
fi

if [[ $sent -eq 0 ]]; then
  echo "No messaging backend configured. Set TELEGRAM_TOKEN+TELEGRAM_CHAT_ID or NTFY_URL." >&2
  exit 1
fi
