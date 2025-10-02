# OpenAI Evals Example: Privacy Policy Classification

This repo contains a complete workflow for running OpenAI evaluations using their Evals API. The scripts are designed to work together, automatically passing variables between steps. 

## Prerequisites

- OpenAI API key set as environment variable: `export OPENAI_API_KEY="your-key-here"`
- `jq` command-line tool for JSON processing
- `curl` for API requests

## Overview

There are five shell scripts that work with OpenAI's eval system:

1. **Upload dataset** - Upload your ground truth evaluation dataset
2. **Create evaluation** - Define the evaluation criteria
3. **Run evaluation** - Execute the evaluation with your prompt
4. **Retrieve results** - Download the evaluation results
5. **Calculate metrics** - Generate detailed metrics including confusion matrix

The scripts automatically export variables between steps, eliminating manual copying of IDs.

## Important: Using `source` for Variable Persistence

**Important**: As a convenience, running scripts 1-3 with `source` will set exported environment variables that persist between scripts. For example:

```bash
source ./1_eval_prep_file_upload.sh [args]
```

This will set the $file_id variable that is used by later scripts. 

Executing scripts normally, e.g. ./1_eval_prep_file_upload <file>, will work but you'll have to manually copy the returned file_id and pass into subsequent scripts. 

## Complete Workflow

### Step 1: Upload Dataset File
```bash
source ./1_eval_prep_file_upload.sh privacy_policy_evals_100_records.jsonl
```
- Uploads your evaluation dataset to OpenAI
- **Exports**: `file_id` (used by step 3)

### Step 2: Create Evaluation Definition
```bash
source ./2_create_eval.sh "Privacy Policy Classifier"
```
- Creates the evaluation configuration
- **Exports**: `eval_id` (used by steps 3 & 4)
- Parameter is optional (defaults to "String Match Eval")

### Step 3: Run the Evaluation
```bash
source ./3_create_eval_run.sh <system_prompt_file> <openai_model>
```
- Creates and starts an evaluation run
- **Requires**: `eval_id` and `file_id` from previous steps and a system prompt file
- **Exports**: `eval_run_id` (used by step 4)
- Second parameter (model) is optional (defaults to gpt-4.1)

### Step 4: Retrieve Results (wait a couple of minutes after running the previous script for your data to be ready)
```bash
eval "$(./4_retrieve_eval_run_results.sh | tail -1)"
```
- Downloads all evaluation results
- **Requires**: `eval_id` and `eval_run_id` from previous steps
- **Exports**: `outfile` (filename of saved results)

Options:
```bash
eval "$(./4_retrieve_eval_run_results.sh my_results.json | tail -1)"  # custom filename
```

### Step 5: Calculate Detailed Metrics
```bash
./5_eval_metrics.sh
```
- Generates confusion matrix and detailed metrics
- **Automatically uses**: `outfile` from step 4
- **Alternative**: `./5_eval_metrics.sh my_results.json` (specify file manually)

## Environment Variables

The scripts automatically export these variables for use in subsequent steps:

- `file_id`: File ID from step 1 (dataset upload)
- `eval_id`: Evaluation ID from step 2 (eval creation)
- `eval_run_id`: Evaluation run ID from step 3 (eval execution)
- `outfile`: Output filename from step 4 (results download)

## Example: Complete Run to Compare Different Prompts

```bash
# Step 1: Upload dataset
source ./1_eval_prep_file_upload.sh privacy_policy_evals_100_records.jsonl
echo "File ID: $file_id"

# Step 2: Create evaluation
source ./2_create_eval.sh "Privacy Policy Risk Classifier"
echo "Eval ID: $eval_id"

# Step 3a: Run evaluation
source ./3_create_eval_run.sh dumb_classifier_prompt.md
echo "Eval Run ID: $eval_run_id"

# Step 4a: Get results (using eval method)
eval "$(./4_retrieve_eval_run_results.sh | tail -1)"
echo "Results saved to: $outfile"

# Step 5a: Calculate metrics
./5_eval_metrics.sh

# Step 3b: Run evaluation
source ./3_create_eval_run.sh risk_classifier_prompt_dspy_optimized_v5.md
echo "Eval Run ID: $eval_run_id"

# Step 4b: Get results (using eval method)
eval "$(./4_retrieve_eval_run_results.sh | tail -1)"
echo "Results saved to: $outfile"

# Step 5b: Calculate metrics
./5_eval_metrics.sh
```


# Example output
Results from the less specific prompt (dumb_classifier_prompt.md)

```
johndamask@Johns-MacBook-Pro-2 policy-reviewer-evals % ./5_eval_metrics.sh
Labels (POS / NEG): high risk / low risk
Total examples: 100
Class distribution: POS=19 (0.190)  NEG=81 (0.810)

Confusion Matrix (rows = actual, cols = predicted):
                PRED_POS    PRED_NEG
ACT_POS               15           4   (TP / FN)
ACT_NEG                5          76   (FP / TN)

Accuracy:              0.9100

Positive class metrics (high risk):
  Precision:           0.7500
  Recall:              0.7895
  F1:                  0.7692
  F2 (recall-weighted):0.7812

Negative class metrics (low risk):
  Precision:           0.9500
  Recall:              0.9383
  F1:                  0.9441

Macro-averaged (both classes):
  Macro Precision:     0.8500
  Macro Recall:        0.8639
  Macro F1:            0.8567

Balanced Accuracy:     0.8639
```

Results from the more specific prompt (risk_classifier_prompt_dspy_optimized_v5.md)

```
johndamask@Johns-MacBook-Pro-2 policy-reviewer-evals % ./5_eval_metrics.sh
Labels (POS / NEG): high risk / low risk
Total examples: 100
Class distribution: POS=19 (0.190)  NEG=81 (0.810)

Confusion Matrix (rows = actual, cols = predicted):
                PRED_POS    PRED_NEG
ACT_POS               19           0   (TP / FN)
ACT_NEG               13          68   (FP / TN)

Accuracy:              0.8700

Positive class metrics (high risk):
  Precision:           0.5938
  Recall:              1.0000
  F1:                  0.7451
  F2 (recall-weighted):0.8796

Negative class metrics (low risk):
  Precision:           1.0000
  Recall:              0.8395
  F1:                  0.9128

Macro-averaged (both classes):
  Macro Precision:     0.7969
  Macro Recall:        0.9198
  Macro F1:            0.8289

Balanced Accuracy:     0.9198
```

---

## Why Does 5_eval_metrics Report So Many Metrics?

OpenAI's eval dashboard shows accuracy, but this can be misleading with imbalanced datasets. The example contained in this repo is a classification problem and the ground truth dataset contains roughly a 90/10 split for Low Risk vs High Risk. So even if accuracy reports 90%, that's not useful information. You want to know about Precision and Recall, too. This script calculates these additional metrics. Specifically, it outputs:

- Confusion matrix
- Precision, recall, F1 for each class
- F2 for the Positive class
- Balanced accuracy
- Macro-averaged metrics

---

## Troubleshooting

### Variables Not Found
If you get "variable not set" errors:
- Ensure you're using `source` not `./script.sh`
- Run previous steps in the correct order
- Check that API calls succeeded (look for error messages in the JSON output)

### API Errors
- Verify your `OPENAI_API_KEY` is set correctly
- Check that file paths exist (for prompt files and datasets)
- Ensure you have sufficient API credits