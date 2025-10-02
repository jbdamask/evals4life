#!/usr/bin/env bash
# Note: set -euo pipefail removed for source compatibility
# When sourced, these options affect the parent shell and can cause terminal exit

#
# STEP 4: Retrieve evaluation results
#
# RECOMMENDED: Use eval method for reliable file creation and variable export:
#   eval "$(./4_retrieve_eval_run_results.sh [OUTFILE|--stdout] | tail -1)"
#
# Note: source method has file creation issues, use eval instead
#
# Requires env vars: eval_id, eval_run_id (from steps 2 & 3)
# Exports: outfile (filename when results saved to file)
# Examples:
#   source ./4_retrieve_eval_run_results.sh                    # saves to auto-generated filename
#   source ./4_retrieve_eval_run_results.sh my_results.json   # saves to custom filename
#   source ./4_retrieve_eval_run_results.sh --stdout          # outputs to terminal only

EVAL_ID="${eval_id:-}"
EVAL_RUN_ID="${eval_run_id:-}"
OUTARG="${1:-}"

if [[ -z "$EVAL_ID" ]]; then
  echo "Error: eval_id environment variable not set. Run script 2 first." >&2
  return 1 2>/dev/null || exit 1
fi

if [[ -z "$EVAL_RUN_ID" ]]; then
  echo "Error: eval_run_id environment variable not set. Run script 3 first." >&2
  return 1 2>/dev/null || exit 1
fi
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
    return 2 2>/dev/null || exit 2
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
  # Use cp instead of mv for more reliable file operations when sourced
  if cp "$TMP" "$OUTFILE" && rm -f "$TMP"; then
    echo "Wrote ${TOTAL} items to ${OUTFILE}" >&2
    export outfile="$OUTFILE"
    echo "export outfile=\"$OUTFILE\""
  else
    echo "Error: Failed to write output file $OUTFILE" >&2
    return 1 2>/dev/null || exit 1
  fi
fi
