: '
This script computes evaluation metrics for a binary classifier from an OpenAI Evals run file.

INTERPRETING THE RESULTS
========================

Metric priorities for this task:
--------------------------------
- Primary: F2 (High Risk) → this is the main number to track, because it
   weights recall more heavily and penalizes missed High Risks (false negatives).
- Supporting: Recall (High Risk) and Precision (High Risk) → these show why
   F2 moves up or down (coverage vs noise).
- Sanity check: Balanced Accuracy → confirms the model isn’t completely
   lopsided toward one class, but it’s not the decision driver.
- Accuracy: lowest value here; easy to inflate with imbalanced data, so report
   it for completeness but don’t optimize for it.


Confusion Matrix
----------------
- Shows counts of model predictions vs. actual labels:
  * TP (True Positives): correctly predicted positives
  * FP (False Positives): negatives incorrectly labeled as positives
  * TN (True Negatives): correctly predicted negatives
  * FN (False Negatives): positives incorrectly labeled as negatives

Accuracy
--------
- Overall proportion of correct predictions: (TP + TN) / Total
- Can be misleading if classes are imbalanced (e.g. 90% Low Risk, 10% High Risk).

Positive Class Metrics (e.g. "High Risk")
-----------------------------------------
- Precision: TP / (TP + FP)
  → When the model predicts positive, how often is it correct?
- Recall: TP / (TP + FN)
  → Of all true positives, how many did the model find?
- F1 Score: Harmonic mean of Precision and Recall
  → Single number balancing precision and recall. Low if either is poor.
- F2 (Positive class only): Like F1 but recall is weighted more heavily,
  so the score penalizes missed High Risk cases (false negatives) more than
  false alarms (false positives).


Negative Class Metrics (e.g. "Low Risk")
----------------------------------------
- Same definitions as above, treating the negative label as the "positive" class.
- Useful when both classes matter.

Macro-Averaged Metrics
----------------------
- Average of Precision, Recall, and F1 across both classes.
- Gives equal weight to minority and majority classes, so it’s fairer than accuracy.

Balanced Accuracy
-----------------
- Average of Recall for each class: (Recall_Pos + Recall_Neg) / 2
- Corrects for class imbalance, showing how well the model does on both sides.

Practical Guidance
------------------
- If Accuracy is high but Recall for the positive class is low, the model is missing many important positives.
- If Precision is low, the model generates too many false alarms.
- F1 is a good summary for the positive class when both false alarms and misses are costly.
- Use Macro F1 and Balanced Accuracy when dataset is imbalanced to avoid being misled by Accuracy.
- F2 (Positive class only): Like F1 but recall is weighted so that false negatives are penalized more than false positives.
'


#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./eval_metrics_v2.sh <evalrun.json> [<POS_LABEL> <NEG_LABEL>]
# Defaults assume labels "High Risk" (positive) and "Low Risk" (negative).
# Requires: jq, awk

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <evalrun.json> [<POS_LABEL> <NEG_LABEL>]" >&2
  exit 1
fi

FILE="$1"
POS_LABEL="${2:-High Risk}"
NEG_LABEL="${3:-Low Risk}"

# Quick deps check
command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }
command -v awk >/dev/null || { echo "awk not found" >&2; exit 1; }

# Normalize labels: trim, collapse spaces, lowercase
canon_label() {
  printf '%s' "$1" \
  | awk '{
      gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", $0);
      gsub(/[ \t]+/, " ", $0);
      for (i=1;i<=length($0);i++){c=substr($0,i,1); printf "%s", tolower(c)}
      printf "\n"
    }'
}

POS_CANON="$(canon_label "$POS_LABEL")"
NEG_CANON="$(canon_label "$NEG_LABEL")"

# Warn if partial page
if jq -e '.has_more == true' "$FILE" >/dev/null 2>&1; then
  echo "⚠️  Warning: This file reports has_more=true. Metrics below reflect ONLY this page." >&2
fi

# 1) Extract truth/pred pairs with jq (robust to array-of-messages or direct string)
JQ_PROGRAM=$(cat <<'JQ'
  .data[]
  | [
      (.datasource_item.ideal // ""),
      (
        (.sample.output[0].content) //     # typical string_match message
        (.sample.output) // ""             # fallback: direct string
      )
    ]
  | @tsv
JQ
)

# 2) Feed pairs to awk to compute metrics
AWK_PROGRAM=$(cat <<'AWK'
BEGIN {
  FS = "\t"
  TP=FP=TN=FN=0
  POS_TRUE=NEG_TRUE=0
  N=0
}
function canon(s,  t) {
  gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
  gsub(/[ \t]+/, " ", s)
  t=""
  for (i=1;i<=length(s);i++){c=substr(s,i,1); t=t tolower(c)}
  return t
}
function safe_div(a,b){ return (b==0)?0:(a/b) }

{
  truth = canon($1)
  pred  = canon($2)
  if (truth == "" || pred == "") next

  if (truth == POS) POS_TRUE++
  else if (truth == NEG) NEG_TRUE++

  if (truth == POS && pred == POS) TP++
  else if (truth == POS && pred == NEG) FN++
  else if (truth == NEG && pred == POS) FP++
  else if (truth == NEG && pred == NEG) TN++

  N++
}
END {
  acc = safe_div(TP+TN, N)

  prec_pos = safe_div(TP, TP+FP)
  rec_pos  = safe_div(TP, TP+FN)
  f1_pos   = (prec_pos+rec_pos==0)?0:(2*prec_pos*rec_pos/(prec_pos+rec_pos))
  # F2 score for positive class (beta=2): emphasizes recall 4x vs precision
  # F_beta = (1+beta^2) * (P*R) / (beta^2*P + R)
  # Here: beta=2 -> (1+4)=5 and beta^2=4
  f2_pos   = ( (4*prec_pos + rec_pos)==0 ) ? 0 : (5*prec_pos*rec_pos/(4*prec_pos + rec_pos))

  prec_neg = safe_div(TN, TN+FN)
  rec_neg  = safe_div(TN, TN+FP)
  f1_neg   = (prec_neg+rec_neg==0)?0:(2*prec_neg*rec_neg/(prec_neg+rec_neg))

  macro_prec = (prec_pos + prec_neg)/2
  macro_rec  = (rec_pos  + rec_neg )/2
  macro_f1   = (f1_pos   + f1_neg  )/2
  bal_acc    = (rec_pos + rec_neg)/2

  printf("Labels (POS / NEG): %s / %s\n", POS, NEG)
  printf("Total examples: %d\n", N)
  printf("Class distribution: POS=%d (%.3f)  NEG=%d (%.3f)\n",
         POS_TRUE, safe_div(POS_TRUE,N), NEG_TRUE, safe_div(NEG_TRUE,N))

  print("")
  print("Confusion Matrix (rows = actual, cols = predicted):")
  printf("                PRED_POS    PRED_NEG\n")
  printf("ACT_POS         %8d    %8d   (TP / FN)\n", TP, FN)
  printf("ACT_NEG         %8d    %8d   (FP / TN)\n", FP, TN)

  print("")
  printf("Accuracy:              %.4f\n", acc)
  print("")
  printf("Positive class metrics (%s):\n", POS)
  printf("  Precision:           %.4f\n", prec_pos)
  printf("  Recall:              %.4f\n", rec_pos)
  printf("  F1:                  %.4f\n", f1_pos)
  printf("  F2 (recall-weighted):%.4f\n", f2_pos)
  print("")
  printf("Negative class metrics (%s):\n", NEG)
  printf("  Precision:           %.4f\n", prec_neg)
  printf("  Recall:              %.4f\n", rec_neg)
  printf("  F1:                  %.4f\n", f1_neg)
  print("")
  printf("Macro-averaged (both classes):\n")
  printf("  Macro Precision:     %.4f\n", macro_prec)
  printf("  Macro Recall:        %.4f\n", macro_rec)
  printf("  Macro F1:            %.4f\n", macro_f1)
  print("")
  printf("Balanced Accuracy:     %.4f\n", bal_acc)
}
AWK
)

# Run
jq -r "$JQ_PROGRAM" "$FILE" \
| awk -v POS="$POS_CANON" -v NEG="$NEG_CANON" "$AWK_PROGRAM"
