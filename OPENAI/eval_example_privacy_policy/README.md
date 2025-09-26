# What to do with this?
There are five shell scripts in this folder along with some relevant input and output files. All of these work using OpenAI's eval system. So you're going to need an `OPENAI_API_KEY`.

The first thing you do is you create a dataset that you want to run an eval against. This is your ground truth dataset. In this repo, it's the privacy_policy_evals_40_records.jsonl file. So you can take a look at that to see what it is. You run the first script and pass that JSONL file to it, and then you check for the `file_id` in the response. 

The next script is where you create the actual eval, and we're doing this with a specific eval for this use case, which is around privacy policy review. 

The third script is when you actually create the eval run. So what you're doing is you're passing in the `EVAL_ID`, the `file_id`, and a prompt markdown file to the script and it'll run the eval for you. 

The fourth script lets you retrieve the results. 

The fifth script calculates important metrics for this eval, so when you're on `OpenAI`'s eval dashboard, it'll show you the accuracy but sometimes that's not enough. For example, in this case, our ground truth dataset contained 90% low-risk entries and 10% high-risk entries. So that means that just by random chance, the accuracy score of the evals for any prompt may look good. So the way to combat this is to create these additional metrics in a confusion matrix, and that's what's output by the fifth script. 

# Walkthrough

./1_eval_prep_file_upload.sh privacy_policy_evals_40_records.jsonl

(save file_id)

./2_create_eval_privacy_policy.sh

(save eval_id)

./3_create_eval_run_privacy_policy.sh <eval id> <file_id> risk_classifier_prompt_no_medium.md gpt-4.1

(save eval_run_id)

./4_retrieve_eval_run_results.sh <EVAL_ID> <EVAL_RUN_ID>

(note output filename)

./5_eval_metrics.sh <output filename>

# Example output
Results from the less specific prompt (dumb_classifier_prompt.md)

```
johndamask@Johns-MacBook-Pro-2 policy-reviewer-evals % ./5_eval_metrics.sh output_items_evalrun_68d6a6bc53388191bf6e389d69b7d966.json
Labels (POS / NEG): high risk / low risk
Total examples: 40
Class distribution: POS=7 (0.175)  NEG=33 (0.825)

Confusion Matrix (rows = actual, cols = predicted):
                PRED_POS    PRED_NEG
ACT_POS                5           2   (TP / FN)
ACT_NEG                6          27   (FP / TN)

Accuracy:              0.8000

Positive class metrics (high risk):
  Precision:           0.4545
  Recall:              0.7143
  F1:                  0.5556

Negative class metrics (low risk):
  Precision:           0.9310
  Recall:              0.8182
  F1:                  0.8710

Macro-averaged (both classes):
  Macro Precision:     0.6928
  Macro Recall:        0.7662
  Macro F1:            0.7133

Balanced Accuracy:     0.7662
```

Results from the more specific prompt (risk_classifier_prompt.md)

```
johndamask@Johns-MacBook-Pro-2 policy-reviewer-evals % ./5_eval_metrics.sh output_items_evalrun_68d6ba1257388191a0d9ddc55036c582.json
Labels (POS / NEG): high risk / low risk
Total examples: 40
Class distribution: POS=7 (0.175)  NEG=33 (0.825)

Confusion Matrix (rows = actual, cols = predicted):
                PRED_POS    PRED_NEG
ACT_POS                6           1   (TP / FN)
ACT_NEG                3          30   (FP / TN)

Accuracy:              0.9000

Positive class metrics (high risk):
  Precision:           0.6667
  Recall:              0.8571
  F1:                  0.7500

Negative class metrics (low risk):
  Precision:           0.9677
  Recall:              0.9091
  F1:                  0.9375

Macro-averaged (both classes):
  Macro Precision:     0.8172
  Macro Recall:        0.8831
  Macro F1:            0.8438

Balanced Accuracy:     0.8831
```
