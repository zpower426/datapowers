#!/usr/bin/env bash
# Scaffold the churn-prediction test project
# Creates the directory structure and test dataset

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-/tmp/datapowers-tests/churn-prediction}"

echo "=== Scaffolding churn-prediction test project ==="
echo "Project dir: $PROJECT_DIR"

mkdir -p "$PROJECT_DIR/data"
mkdir -p "$PROJECT_DIR/artifacts/transformers"
mkdir -p "$PROJECT_DIR/docs/datapowers/plans"
mkdir -p "$PROJECT_DIR/docs/datapowers/specs"
mkdir -p "$PROJECT_DIR/docs/datapowers/features"

# Copy design and plan
cp "$SCRIPT_DIR/design.md" "$PROJECT_DIR/docs/datapowers/specs/churn-analysis.md"
cp "$SCRIPT_DIR/plan.md" "$PROJECT_DIR/docs/datapowers/plans/churn-analysis.md"

# Generate test dataset
python3 - <<'PYEOF'
import csv
import random
import math
import os
import sys

project_dir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/datapowers-tests/churn-prediction"
random.seed(42)

rows = []
for i in range(200):
    age = random.randint(18, 70)
    tenure = random.randint(1, 60)
    monthly_spend = round(random.uniform(20, 200), 2)
    support_calls = random.randint(0, 10)
    # Simple rule: churn if support_calls > 6 or tenure < 6
    churned = 1 if (support_calls > 6 or tenure < 6) else 0
    rows.append([i, age, tenure, monthly_spend, support_calls, churned])

output_path = os.path.join(project_dir, "data/churn.csv")
with open(output_path, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "age", "tenure_months", "monthly_spend", "support_calls", "churned"])
    writer.writerows(rows)

churn_rate = sum(r[5] for r in rows) / len(rows)
print(f"Dataset created: {output_path}")
print(f"  Rows: {len(rows)}")
print(f"  Churn rate: {churn_rate:.1%}")
PYEOF "$PROJECT_DIR"

echo ""
echo "Scaffold complete. Project ready at: $PROJECT_DIR"
echo ""
echo "To run analysis:"
echo "  cd $PROJECT_DIR"
echo "  claude -p 'Execute the analysis plan at docs/datapowers/plans/churn-analysis.md using subagent-driven-analysis'"
