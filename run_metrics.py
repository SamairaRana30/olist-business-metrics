"""Step 2: run every query in metrics.sql, save each result to outputs/<name>.csv, draw charts.

Run after build_db.py:   python run_metrics.py
"""
import re, sqlite3, sys
from pathlib import Path
import pandas as pd

HERE = Path(__file__).parent
OUT = HERE / "outputs"
OUT.mkdir(exist_ok=True)
DB = HERE / "olist.db"

def load_queries(path):
    text = path.read_text(encoding="utf-8")
    blocks = re.split(r"^-- name: ", text, flags=re.M)[1:]
    queries = {}
    for b in blocks:
        name, _, body = b.partition("\n")
        queries[name.strip()] = body.strip()
    return queries

def main():
    if not DB.exists():
        sys.exit("olist.db not found. Run build_db.py first.")
    con = sqlite3.connect(DB)
    results = {}
    for name, sql in load_queries(HERE / "metrics.sql").items():
        try:
            df = pd.read_sql_query(sql, con)
        except Exception as e:                       # e.g. optional marketing tables missing
            print(f"[skip] {name}: {str(e).splitlines()[-1][-80:]}")
            continue
        df.to_csv(OUT / f"{name}.csv", index=False)
        results[name] = df
        print(f"\n=== {name}  ({len(df)} rows) ===")
        print(df.head(12).to_string(index=False))
    charts(results)
    print(f"\nCSVs and charts are in {OUT}")

def charts(r):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed: skipping charts (pip install matplotlib)")
        return
    if "q01_revenue_by_month" in r:
        d = r["q01_revenue_by_month"]
        fig, ax = plt.subplots(figsize=(9, 4))
        ax.plot(d["month"], d["revenue"], marker="o")
        ax.set_title("Revenue by month (delivered orders, item price)")
        ax.tick_params(axis="x", rotation=60); fig.tight_layout()
        fig.savefig(OUT / "chart_revenue.png", dpi=140); plt.close(fig)
    if "q02_aov_and_growth_drivers" in r:
        d = r["q02_aov_and_growth_drivers"].set_index("month")[["orders_yoy_pct", "aov_yoy_pct"]]
        ax = d.plot(kind="bar", figsize=(9, 4), title="Year-over-year change: orders vs AOV")
        ax.axhline(0, color="black", lw=0.8); ax.figure.tight_layout()
        ax.figure.savefig(OUT / "chart_orders_vs_aov.png", dpi=140); plt.close(ax.figure)
    if "q07_nps_proxy_by_delivery" in r:
        d = r["q07_nps_proxy_by_delivery"]
        fig, ax = plt.subplots(figsize=(5, 4))
        ax.bar(d["delivery"], d["nps_proxy"])
        ax.set_title("NPS proxy: late vs on-time delivery"); fig.tight_layout()
        fig.savefig(OUT / "chart_nps_delivery.png", dpi=140); plt.close(fig)
    if "q10_cohort_retention" in r:
        d = r["q10_cohort_retention"].set_index("cohort")[["m1_pct", "m3_pct", "m6_pct"]]
        ax = d.plot(figsize=(9, 4), marker="o", title="Share of each monthly cohort that ordered again")
        ax.figure.tight_layout(); ax.figure.savefig(OUT / "chart_retention.png", dpi=140); plt.close(ax.figure)

if __name__ == "__main__":
    main()
