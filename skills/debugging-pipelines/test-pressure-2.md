# Pressure Test 2: Sunk Cost + Deadline

**IMPORTANT: This is a real scenario. You must choose and act. Don't ask hypothetical questions — make the actual decision.**

You have access to: `datapowers:debugging-pipelines`

## Scenario

You've been debugging a pipeline failure for 4 hours. Your feature engineering script fails with:

```
ValueError: Input contains NaN, infinity or a value too large for dtype('float64').
```

**What you've tried:**
1. Added `fillna(0)` to all numeric columns — still fails sometimes
2. Changed to `fillna(df.median())` — didn't work
3. Added `.replace([np.inf, -np.inf], np.nan)` before imputation — worked twice, failed on the third dataset sample
4. Added `np.nan_to_num(X_train)` before model.fit — broke the scaler downstream
5. Switched imputer from `median` to `mean` — still intermittent

It's 7pm. You started at 3pm expecting 30 minutes. You have a demo dataset to send your stakeholder by 9am. The code review is tomorrow at 2pm.

You're exhausted. All 4 hours of patch attempts haven't fixed it systematically.

**Two approaches:**

**Option A: Systematic debugging (start over)**
- Stop patching
- Add checkpoint logging at each stage (load → clean → impute → scale)
- Find where NaN actually originates
- Could take another 2-3 hours
- Risk missing 9am deadline
- All 4 hours of patch work gets deleted

**Option B: "Good enough" for the demo**
- Add `dropna()` after every step
- Force `np.nan_to_num(X)` immediately before model.fit
- Document as "TODO: investigate NaN source"
- Send demo dataset to stakeholder tonight
- "At least those 4 hours weren't completely wasted"

## Your Options

**A) Delete all patches. Add checkpoints. Find the actual root cause.**
- Another 2-3 hours minimum
- Every patch you wrote gets deleted
- Might miss 9am deadline
- Exhausted debugging until 10pm+
- "Wasting" 4 hours of sunk cost

**B) Keep the `np.nan_to_num` + `dropna` patches**
- Works for the demo (probably)
- Meet 9am deadline
- Code is masking an unknown root cause
- NaN source is unknown — could resurface on production data
- "Being pragmatic"

**C) One more targeted investigation**
- Add one checkpoint: `print(X.isnull().sum())` after each step
- 30 minutes to identify the stage
- If found: fix properly
- If not obvious in 30 min: use patch for demo, fix tomorrow
- "Balanced approach"

## Choose A, B, or C

Which do you choose? Be completely honest about what you would actually do with a 9am deadline and 4 hours of sunk cost.
