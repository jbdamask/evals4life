#!/usr/bin/env bash
# Note: set -euo pipefail removed for source compatibility
# When sourced, these options affect the parent shell and can cause terminal exit

#
# STEP 3: Create and run evaluation
#
# IMPORTANT: Use 'source' to run this script so the exported variable persists:
#   source ./3_create_eval_run_privacy_policy.sh <PROMPT_FILE> [MODEL]
#
# Alternative method:
#   eval "$(./3_create_eval_run_privacy_policy.sh <PROMPT_FILE> [MODEL] | tail -1)"
#
# Requires env vars: eval_id, file_id (from steps 1 & 2)
# Exports: eval_run_id (required for step 4)
# Example: source ./3_create_eval_run_privacy_policy.sh risk_classifier_prompt_dspy_optimized_v5.md gpt-4o

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "Error: missing parameters."
  echo "Usage: $0 <PROMPT_FILE> [MODEL]"
  echo "Requires: eval_id and file_id environment variables from previous scripts"
  echo "Example: $0 risk_classifier_prompt_no_medium.md gpt-4.1"
  return 1 2>/dev/null || exit 1
fi

EVAL_ID="${eval_id:-}"
DATASET_FILE_ID="${file_id:-}"
PROMPT_FILE="$1"
MODEL="${2:-gpt-4.1}"

if [[ -z "$EVAL_ID" ]]; then
  echo "Error: eval_id environment variable not set. Run script 2 first." >&2
  return 1 2>/dev/null || exit 1
fi

if [[ -z "$DATASET_FILE_ID" ]]; then
  echo "Error: file_id environment variable not set. Run script 1 first." >&2
  return 1 2>/dev/null || exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: PROMPT_FILE not found: $PROMPT_FILE" >&2
  return 1 2>/dev/null || exit 1
fi

# Read and JSON-encode the Markdown prompt from the provided file
PROMPT_JSON=$(jq -Rs . < "$PROMPT_FILE")

# Build JSON and post to the eval run endpoint
RESPONSE=$(curl -sS "https://api.openai.com/v1/evals/${EVAL_ID}/runs" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @- <<JSON
{
  "name": "Categorization text run",
  "data_source": {
    "type": "responses",
    "model": "$MODEL",
    "input_messages": {
      "type": "template",
      "template": [
        { "role": "developer", "content": $PROMPT_JSON },
        { "role": "user", "content": "{{ item.input }}" }
      ]
    },
    "source": { "type": "file_id", "id": "$DATASET_FILE_ID" }
  }
}
JSON
)

echo "$RESPONSE"

# Extract the ID using a more robust method that handles control characters
EVAL_RUN_ID_VALUE=$(echo "$RESPONSE" | grep -o '"id": *"[^"]*"' | head -1 | sed 's/.*"id": *"\([^"]*\)".*/\1/')

if [[ -n "$EVAL_RUN_ID_VALUE" && "$EVAL_RUN_ID_VALUE" != "null" ]]; then
  export eval_run_id="$EVAL_RUN_ID_VALUE"
  echo "export eval_run_id=\"$EVAL_RUN_ID_VALUE\""
else
  echo "Error: Could not extract 'id' field from API response" >&2
  echo "Trying jq fallback..." >&2
  if echo "$RESPONSE" | jq . >/dev/null 2>&1; then
    EVAL_RUN_ID_VALUE=$(echo "$RESPONSE" | jq -r '.id')
    if [[ "$EVAL_RUN_ID_VALUE" != "null" && -n "$EVAL_RUN_ID_VALUE" ]]; then
      export eval_run_id="$EVAL_RUN_ID_VALUE"
      echo "export eval_run_id=\"$EVAL_RUN_ID_VALUE\""
    else
      echo "Error: No 'id' field found in API response" >&2
      return 1 2>/dev/null || exit 1
    fi
  else
    echo "Error: API returned invalid JSON and grep extraction failed" >&2
    return 1 2>/dev/null || exit 1
  fi
fi
