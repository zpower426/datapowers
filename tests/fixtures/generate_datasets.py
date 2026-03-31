import pandas as pd
import numpy as np
from pathlib import Path

def generate_datasets(output_dir="."):
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    # 共同特征：10个特征，包含数值和类别
    def get_features(n):
        np.random.seed(42)
        return pd.DataFrame({
            "age": np.random.randint(18, 75, n),
            "income": np.random.lognormal(mean=10.5, sigma=0.8, size=n),
            "tenure_months": np.random.randint(1, 60, n),
            "support_calls": np.random.poisson(lam=2.5, size=n),
            "region": np.random.choice(["North", "South", "East", "West"], n, p=[0.4, 0.3, 0.2, 0.1]),
            "plan_type": np.random.choice(["Basic", "Premium", "Enterprise"], n, p=[0.6, 0.3, 0.1]),
            "is_active": np.random.choice([0, 1], n, p=[0.1, 0.9])
        })
    
    # 1. 结构平衡的标准数据集 (N=1000, 目标变量比例 ~50%)
    n_balanced = 1000
    df1 = get_features(n_balanced)
    # y = fn(features) + noise
    logits = (df1["support_calls"] * 0.5) - (df1["tenure_months"] * 0.1) + np.random.normal(0, 1, n_balanced)
    probs = 1 / (1 + np.exp(-logits))
    # 调整阈值使正例接近 50%
    threshold = np.median(probs) 
    df1["churn"] = (probs > threshold).astype(int)
    df1.to_csv(f"{output_dir}/dataset_1_balanced.csv", index=False)
    print(f"Dataset 1 (Balanced) created: {output_dir}/dataset_1_balanced.csv, shape={df1.shape}, churn rate={df1['churn'].mean():.2f}")

    # 2. 极度不平衡的数据集 (N=10000, 目标变量比例 ~1%)
    n_imbalanced = 10000
    df2 = get_features(n_imbalanced)
    # y = rare event
    logits2 = (df2["support_calls"] * 0.8) - (df2["tenure_months"] * 0.1) + np.random.normal(0, 1, n_imbalanced)
    probs2 = 1 / (1 + np.exp(-logits2))
    # 取 top 1% 作为 churn
    threshold2 = np.percentile(probs2, 99)
    df2["fraud_detected"] = (probs2 > threshold2).astype(int)
    df2.to_csv(f"{output_dir}/dataset_2_imbalanced.csv", index=False)
    print(f"Dataset 2 (Imbalanced) created: {output_dir}/dataset_2_imbalanced.csv, shape={df2.shape}, fraud rate={df2['fraud_detected'].mean():.4f}")

    # 3. 统计压力测试的小样本数据集 (N=150)
    n_small = 150
    df3 = get_features(n_small)
    logits3 = (df3["support_calls"] * 0.5) - (df3["tenure_months"] * 0.1) + np.random.normal(0, 1, n_small)
    probs3 = 1 / (1 + np.exp(-logits3))
    df3["churn"] = (probs3 > np.median(probs3)).astype(int)
    # 故意引入一个完全共线性的泄露特征用于测试 leakage-guard
    df3["churn_reason_code"] = df3["churn"].apply(lambda x: np.random.choice(["pricing", "support", "competitor"]) if x == 1 else "none")
    df3.to_csv(f"{output_dir}/dataset_3_small_sample.csv", index=False)
    print(f"Dataset 3 (Small Sample & Leaky) created: {output_dir}/dataset_3_small_sample.csv, shape={df3.shape}, churn rate={df3['churn'].mean():.2f}")

if __name__ == "__main__":
    import sys
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    generate_datasets(out_dir)
