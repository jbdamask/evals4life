#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./get_all_eval_output_items.sh <EVAL_ID> <EVAL_RUN_ID> [OUTFILE]
#   ./get_all_eval_output_items.sh <EVAL_ID> <EVAL_RUN_ID> --stdout
#
# Requires: jq, curl, $OPENAI_API_KEY

if [[ $# -lt 2 || -z "${1:-}" || -z "${2:-}" ]]; then
  echo "Usage: $0 <EVAL_ID> <EVAL_RUN_ID> [OUTFILE|--stdout]" >&2
  exit 1
fi

EVAL_ID="$1"
EVAL_RUN_ID="$2"
OUTARG="${3:-}"
TO_STDOUT=false
if [[ "$OUTARG" == "--stdout" ]]; then
  TO_STDOUT=true
  OUTFILE=""     # unused
else
  OUTFILE="${OUTARG:-output_items_${EVAL_RUN_ID}.json}"
fi

BASE_URL="https://api.openai.com/v1/evals/${EVAL_ID}/runs/${EVAL_RUN_ID}/output_items"
HEADERS=(-H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json")

# Aggregate into a temp file; start with a list wrapper
TMP="$(mktemp)"
echo '{"object":"list","data":[]}' > "$TMP"

AFTER=""
PAGE=1
TOTAL=0

while true; do
  URL="${BASE_URL}?limit=100"
  [[ -n "$AFTER" ]] && URL="${URL}&after=${AFTER}"

  RESP="$(curl -sS "$URL" "${HEADERS[@]}")"

  if ! echo "$RESP" | jq -e . >/dev/null 2>&1; then
    echo "Error: non-JSON response on page $PAGE" >&2
    echo "$RESP" >&2
    exit 2
  fi

  # Extract page data and append
  PAGE_DATA="$(echo "$RESP" | jq '.data')"
  jq --argjson page "$PAGE_DATA" '.data += $page' "$TMP" > "${TMP}.next"
  mv "${TMP}.next" "$TMP"

  # Track pagination
  HAS_MORE="$(echo "$RESP" | jq -r '.has_more // false')"
  LAST_ID="$(echo "$RESP" | jq -r '.last_id // empty')"
  COUNT_THIS="$(echo "$PAGE_DATA" | jq 'length')"
  TOTAL=$((TOTAL + COUNT_THIS))

  echo "Fetched page $PAGE: +${COUNT_THIS} items (total=${TOTAL}); has_more=${HAS_MORE}" >&2

  if [[ "$HAS_MORE" != "true" || -z "$LAST_ID" ]]; then
    break
  fi
  AFTER="$LAST_ID"
  PAGE=$((PAGE + 1))
done

# Output
if $TO_STDOUT; then
  cat "$TMP"   # JSON to stdout only
else
  mv "$TMP" "$OUTFILE"
  echo "Wrote ${TOTAL} items to ${OUTFILE}" >&2
fi
