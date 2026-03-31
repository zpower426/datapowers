#!/usr/bin/env bash
# Bisection script to find which pipeline step creates bad artifacts
# Usage: ./pipeline-pollution-detection.sh <artifact_to_check> [pipeline_scripts_pattern]
#
# Example: Check which step first creates NaN values in X_train.csv
#   ./pipeline-pollution-detection.sh artifacts/X_train.csv
#
# Example: Check which step first creates zero-variance columns
#   ./pipeline-pollution-detection.sh artifacts/zero_variance_flag "scripts/pipeline_*.py"

set -e

ARTIFACT_CHECK="${1:-artifacts/X_train.csv}"
SCRIPT_PATTERN="${2:-scripts/pipeline_*.py}"

echo "Pipeline Pollution Detection"
echo "============================"
echo "Checking: $ARTIFACT_CHECK"
echo "Script pattern: $SCRIPT_PATTERN"
echo ""

# If checking a CSV, validate it with Python
check_artifact() {
    local path="$1"
    if [ ! -e "$path" ]; then
        return 1  # Not found = clean
    fi

    if [[ "$path" == *.csv ]]; then
        # Check for NaN values or zero-variance columns
        python3 - "$path" <<'PYEOF'
import sys
import pandas as pd
import numpy as np

path = sys.argv[1]
try:
    df = pd.read_csv(path)
    nan_count = df.isnull().sum().sum()
    inf_count = np.isinf(df.select_dtypes('number')).sum().sum()
    zero_var = (df.select_dtypes('number').var() == 0).sum()

    if nan_count > 0 or inf_count > 0 or zero_var > 0:
        print(f"POLLUTION DETECTED: NaN={nan_count}, Inf={inf_count}, ZeroVar={zero_var}")
        sys.exit(0)  # exit 0 = pollution found
    sys.exit(1)  # exit 1 = clean
except Exception as e:
    print(f"ERROR reading {path}: {e}")
    sys.exit(0)  # treat errors as pollution
PYEOF
        return $?
    else
        # For non-CSV: just check existence
        return 0
    fi
}

# Get list of pipeline scripts
SCRIPT_FILES=$(find . -name "*.py" -path "${SCRIPT_PATTERN}" 2>/dev/null | sort || echo "")

if [ -z "$SCRIPT_FILES" ]; then
    echo "No pipeline scripts found matching: $SCRIPT_PATTERN"
    echo ""
    echo "Checking artifact directly..."

    if check_artifact "$ARTIFACT_CHECK"; then
        echo "Pollution found in: $ARTIFACT_CHECK"
        python3 - "$ARTIFACT_CHECK" <<'PYEOF'
import sys
import pandas as pd
import numpy as np

path = sys.argv[1]
df = pd.read_csv(path)
print("\nArtifact analysis:")
print(f"  Shape: {df.shape}")
nan_cols = df.columns[df.isnull().any()].tolist()
if nan_cols:
    print(f"  NaN columns: {nan_cols}")
    print(f"  NaN counts:\n{df[nan_cols].isnull().sum().to_string()}")
zero_var_cols = df.columns[df.select_dtypes('number').var() == 0].tolist()
if zero_var_cols:
    print(f"  Zero-variance columns: {zero_var_cols}")
PYEOF
    else
        echo "No pollution detected in: $ARTIFACT_CHECK"
    fi
    exit 0
fi

TOTAL=$(echo "$SCRIPT_FILES" | wc -l | tr -d ' ')
echo "Found $TOTAL pipeline scripts"
echo ""

COUNT=0
for SCRIPT in $SCRIPT_FILES; do
    COUNT=$((COUNT + 1))

    # Skip if pollution already exists before running
    if check_artifact "$ARTIFACT_CHECK" 2>/dev/null; then
        echo "  Pollution exists before step $COUNT/$TOTAL — skipping $SCRIPT"
        continue
    fi

    echo "[$COUNT/$TOTAL] Running: $SCRIPT"
    python3 "$SCRIPT" > /tmp/pipeline-step-output.log 2>&1 || true

    # Check if pollution appeared after this script
    if check_artifact "$ARTIFACT_CHECK" 2>/dev/null; then
        echo ""
        echo "POLLUTER FOUND!"
        echo "  Script: $SCRIPT"
        echo "  Artifact: $ARTIFACT_CHECK"
        echo ""
        echo "Script output:"
        cat /tmp/pipeline-step-output.log | tail -20
        echo ""
        echo "To investigate:"
        echo "  python3 $SCRIPT  # Run just this step"
        echo "  cat $SCRIPT      # Review step code"
        exit 1
    fi
done

echo ""
echo "No polluter found — all steps clean!"
exit 0
