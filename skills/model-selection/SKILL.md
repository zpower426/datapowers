---
name: model-selection
description: "Use when choosing which model(s) to train. Enforces baseline comparison before hyperparameter tuning, and correct metric selection for the task type."
---

# Model Selection

Systematic selection of the best model through baseline comparison and rigorous hyperparameter optimization.

**Iron Law: NO HYPERPARAMETER TUNING WITHOUT BASELINE COMPARISON FIRST. METRIC MUST MATCH BUSINESS OBJECTIVE.**

<HARD-GATE>
Do NOT tune a single model without first establishing baselines for multiple model families. Do NOT select a model based on accuracy alone for imbalanced classification tasks.
</HARD-GATE>

## Checklist

1. **Confirm correct metric** — must match task type and business objective
2. **Establish dummy baseline** — minimum bar any model must beat
3. **Train 4 baseline models** — without tuning
4. **Cross-validate all baselines** — stratified k-fold, log all results
5. **Statistical comparison** — Wilcoxon test on CV scores
6. **Select top 2 candidates** — for hyperparameter optimization
7. **Run Bayesian HPO** — Optuna, minimum 50 trials, log to MLflow
8. **Final model selection** — based on CV score, NOT test set
9. **Document selection rationale** — model choice + justification

## Step 1: Choose the Right Metric

| Task | Metric (Primary) | Metric (Secondary) | Never Use |
|---|---|---|---|
| Binary classification, balanced | F1 | AUC-ROC | — |
| Binary classification, imbalanced | F1-macro or PR-AUC | Recall | Accuracy alone |
| Multi-class classification | F1-macro | — | Accuracy alone |
| Regression | RMSE | MAE, R² | R² alone |
| Ranking | NDCG | MAP | Accuracy |
| Time series | MAPE or SMAPE | RMSE | R² |

```python
# For imbalanced classification: always check the ratio first
minority_ratio = df[target].value_counts(normalize=True).min()
if minority_ratio < 0.20:
    print(f"⚠️ Imbalanced dataset ({minority_ratio:.1%} minority)")
    print("Primary metric: F1-macro or PR-AUC — NOT accuracy")
    PRIMARY_METRIC = 'f1_macro'
```

## Step 2: Dummy Baseline

```python
from sklearn.dummy import DummyClassifier, DummyRegressor
from sklearn.model_selection import cross_val_score

dummy = DummyClassifier(strategy='most_frequent')  # or 'stratified', 'uniform'
dummy_scores = cross_val_score(dummy, X_train, y_train,
                                cv=5, scoring='f1_macro')
print(f"Dummy baseline: {dummy_scores.mean():.3f} ± {dummy_scores.std():.3f}")
BASELINE_SCORE = dummy_scores.mean()
```

Any model that fails to beat the dummy baseline has NO predictive value.

## Step 3: Train 4 Baseline Models

```python
from sklearn.linear_model import LogisticRegression, Ridge
from sklearn.ensemble import RandomForestClassifier
from lightgbm import LGBMClassifier
from xgboost import XGBClassifier

baselines = {
    'LogisticRegression': LogisticRegression(max_iter=1000, random_state=42),
    'RandomForest':       RandomForestClassifier(n_estimators=100, random_state=42),
    'LightGBM':           LGBMClassifier(random_state=42, verbose=-1),
    'XGBoost':            XGBClassifier(random_state=42, eval_metric='logloss'),
}

results = {}
for name, model in baselines.items():
    scores = cross_val_score(model, X_train, y_train,
                              cv=StratifiedKFold(n_splits=5, shuffle=True, random_state=42),
                              scoring=PRIMARY_METRIC)
    results[name] = scores
    print(f"{name}: {scores.mean():.4f} ± {scores.std():.4f}")
```

**Use `n_splits=5` minimum. For imbalanced data, always use `StratifiedKFold`.**

## Step 4: Statistical Comparison

```python
from scipy.stats import wilcoxon

best_name = max(results, key=lambda k: results[k].mean())
best_scores = results[best_name]

print(f"\nBest baseline: {best_name}")
for name, scores in results.items():
    if name == best_name:
        continue
    stat, p = wilcoxon(best_scores, scores)
    sig = "✅ significantly better" if p < 0.05 else "⚠️ NOT significantly better"
    print(f"  vs {name}: p={p:.4f} — {sig}")
```

**If the best model is NOT significantly better than the second-best, keep both as candidates for HPO.**

## Step 5: Bayesian HPO with Optuna

```python
import optuna
import mlflow

optuna.logging.set_verbosity(optuna.logging.WARNING)

def objective(trial):
    params = {
        'n_estimators': trial.suggest_int('n_estimators', 100, 1000),
        'max_depth': trial.suggest_int('max_depth', 3, 10),
        'learning_rate': trial.suggest_float('learning_rate', 1e-4, 0.3, log=True),
        'subsample': trial.suggest_float('subsample', 0.5, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
    }
    model = LGBMClassifier(**params, random_state=42, verbose=-1)
    scores = cross_val_score(model, X_train, y_train,
                              cv=StratifiedKFold(5, shuffle=True, random_state=42),
                              scoring=PRIMARY_METRIC)

    # Log every trial to MLflow
    with mlflow.start_run(nested=True):
        mlflow.log_params(params)
        mlflow.log_metric('cv_f1_mean', scores.mean())
        mlflow.log_metric('cv_f1_std', scores.std())

    return scores.mean()

with mlflow.start_run(run_name="hpo_lgbm"):
    study = optuna.create_study(direction='maximize',
                                 sampler=optuna.samplers.TPESampler(seed=42))
    study.optimize(objective, n_trials=50, show_progress_bar=True)

    best_params = study.best_params
    print(f"Best CV score: {study.best_value:.4f}")
    print(f"Best params: {best_params}")
    mlflow.log_params(best_params)
    mlflow.log_metric('best_cv_score', study.best_value)
```

**Minimum 50 trials. For large datasets, use `n_trials=100`.**

## Step 6: Final Model Selection

Select the model with the best mean CV score — **NOT based on test set performance**:

```python
# NEVER touch the test set for model selection
CHOSEN_MODEL = LGBMClassifier(**best_params, random_state=42)
CHOSEN_MODEL.fit(X_train, y_train)

print("✅ Model selected: LightGBM with tuned parameters")
print("Reason: Best mean CV F1-macro across 5 folds")
print("Test set has NOT been touched.")
```

## Selection Rationale Document

Save to `docs/datapowers/models/YYYY-MM-DD-model-selection.md`:

```markdown
# Model Selection: [Task Name]

## Task Type: [classification / regression]
## Primary Metric: [metric name + justification]

## Baseline Results
| Model | CV Mean | CV Std |
|---|---|---|
| Dummy | X.XXX | X.XXX |
| LogisticRegression | X.XXX | X.XXX |
| [etc.] | | |

## HPO Results
- Candidates: [model names]
- Trials: [count]
- Best CV score: [value]
- Best params: [params]

## Final Choice: [model name]
## Rationale: [1-2 sentences]
## Test set status: NOT EVALUATED YET
```

## Red Flags

**Never:**
- Select a model based on test set performance
- Skip the dummy baseline
- Use accuracy as primary metric for imbalanced data
- Tune a single model without comparing baselines
- Run fewer than 50 HPO trials on a non-trivial dataset
- Use grid search when dataset > 10,000 rows (use Optuna)
