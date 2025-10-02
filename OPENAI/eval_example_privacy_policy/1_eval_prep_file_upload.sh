#!/usr/bin/env bash
#
# STEP 1: Upload dataset file to OpenAI
#
# IMPORTANT: Use 'source' to run this script so the exported variable persists:
#   source ./1_eval_prep_file_upload.sh <FILE>
#
# Alternative method:
#   eval "$(./1_eval_prep_file_upload.sh <FILE> | tail -1)"
#
# Exports: file_id (required for subsequent scripts)
# Example: source ./1_eval_prep_file_upload.sh privacy_policy_evals_40_records.jsonl

FILE=$1
RESPONSE=$(curl https://api.openai.com/v1/files \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F purpose="evals" \
  -F file="@$FILE")

echo "$RESPONSE"

FILE_ID=$(echo "$RESPONSE" | jq -r '.id')
export file_id="$FILE_ID"
echo "export file_id=\"$FILE_ID\""

