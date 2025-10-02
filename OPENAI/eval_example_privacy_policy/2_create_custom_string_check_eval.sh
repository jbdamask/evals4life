#!/usr/bin/env bash
#
# STEP 2: Create evaluation definition
#
# IMPORTANT: Use 'source' to run this script so the exported variable persists:
#   source ./2_create_eval_privacy_policy.sh [EVAL_NAME]
#
# Alternative method:
#   eval "$(./2_create_eval_privacy_policy.sh [EVAL_NAME] | tail -1)"
#
# Exports: eval_id (required for subsequent scripts)
# Example: source ./2_create_eval_privacy_policy.sh "Privacy Policy Classifier"

EVAL_NAME="${1:-String Match Eval}"

RESPONSE=$(curl https://api.openai.com/v1/evals \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
    {
        "name": "$EVAL_NAME",
        "data_source_config": {
            "type": "custom",
            "item_schema": {
                "type": "object",
                "properties": {
                    "input": { "type": "string" },
                    "ideal": { "type": "string" }
                },
                "required": ["input", "ideal"]
            },
            "include_sample_schema": true
        },
        "testing_criteria": [
            {
                "type": "string_check",
                "name": "Match output to human label",
                "input": "{{ sample.output_text }}",
                "operation": "eq",
                "reference": "{{ item.ideal }}"
            }
        ]
    }
EOF
)

echo "$RESPONSE"

EVAL_ID_VALUE=$(echo "$RESPONSE" | jq -r '.id')
export eval_id="$EVAL_ID_VALUE"
echo "export eval_id=\"$EVAL_ID_VALUE\""
