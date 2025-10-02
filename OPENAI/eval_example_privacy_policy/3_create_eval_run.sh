#!/usr/bin/env bash
set -euo pipefail

# Require: EVAL_ID, DATASET_FILE_ID, PROMPT_FILE
# Optional: MODEL (defaults to gpt-4.1)
if [[ $# -lt 3 || -z "${1:-}" || -z "${2:-}" || -z "${3:-}" ]]; then
  echo "Error: missing parameters."
  echo "Usage: $0 <EVAL_ID> <DATASET_FILE_ID> <PROMPT_FILE> [MODEL]"
  echo "Example: $0 eval_68cd63c05658819180f880d7b8c973 file-UrfsbosE8eiYrg6X2Yz1W risk_classifier_prompt_no_medium.md gpt-4.1"
  exit 1
fi

EVAL_ID="$1"
DATASET_FILE_ID="$2"
PROMPT_FILE="$3"
MODEL="${4:-gpt-4.1}"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: PROMPT_FILE not found: $PROMPT_FILE" >&2
  exit 1
fi

# Read and JSON-encode the Markdown prompt from the provided file
PROMPT_JSON=$(jq -Rs . < "$PROMPT_FILE")

# Build JSON and post to the eval run endpoint
curl -sS "https://api.openai.com/v1/evals/${EVAL_ID}/runs" \
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
