EVAL_NAME="${1:-String Match Eval}"

curl https://api.openai.com/v1/evals \
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
