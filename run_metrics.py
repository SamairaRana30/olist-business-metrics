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
        from matplotlib.ticker import FuncFormatter
    except ImportError:
        print("matplotlib not installed: skipping charts (pip install matplotlib)")
        return
    blue, orange, grey = "#1f77b4", "#ff7f0e", "#888888"

    if "q01_revenue_by_month" in r:
        d = r["q01_revenue_by_month"]
        fig, ax = plt.subplots(figsize=(9, 4.5))
        ax.plot(d["month"], d["revenue"] / 1000, marker="o", color=blue)
        ax.set_title("Monthly revenue grew fast in 2017, then levelled off")
        ax.set_ylabel("Revenue (R$ thousand, delivered orders)")
        ax.set_xlabel("Purchase month")
        ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}k"))
        if "2017-11" in set(d["month"]):
            y = float(d.loc[d["month"] == "2017-11", "revenue"].iloc[0]) / 1000
            ax.annotate("Nov 2017: Black Friday\n(24 Nov = 15% of the month)", xy=("2017-11", y),
                        xytext=("2017-03", y * 0.93), arrowprops=dict(arrowstyle="->", color=grey), color="#333333")
        ax.tick_params(axis="x", rotation=60); ax.grid(axis="y", alpha=0.3)
        fig.tight_layout(); fig.savefig(OUT / "chart_revenue.png", dpi=140); plt.close(fig)

    if "q01_revenue_by_month" in r:
        d = r["q01_revenue_by_month"].copy()
        d["aov"] = d["revenue"] / d["orders"]
        fig, ax = plt.subplots(figsize=(9, 4.5))
        ax.bar(d["month"], d["orders"], color=blue, alpha=0.8)
        ax.set_ylabel("Orders per month", color=blue)
        ax2 = ax.twinx()
        ax2.plot(d["month"], d["aov"], color=orange, marker="o")
        ax2.set_ylabel("Average order value (R$)", color=orange)
        ax2.set_ylim(0, max(d["aov"]) * 1.3)
        ax.set_title("Growth came from more orders, not bigger orders")
        ax.tick_params(axis="x", rotation=60); fig.tight_layout()
        fig.savefig(OUT / "chart_orders_vs_aov.png", dpi=140); plt.close(fig)

    if "q07_nps_proxy_by_delivery" in r:
        d = r["q07_nps_proxy_by_delivery"].set_index("delivery").loc[["on_time", "late", "all"]].reset_index()
        d["label"] = d["delivery"].map({"on_time": "On time", "late": "Late", "all": "All orders"})
        fig, ax = plt.subplots(figsize=(6, 4.5))
        bars = ax.bar(d["label"], d["nps_proxy"], color=[blue, orange, grey])
        ax.axhline(0, color="black", lw=0.8)
        ax.bar_label(bars, fmt="%+.0f", padding=3)
        ax.set_ylabel("NPS proxy (% 5-star minus % 1-3 star)")
        ax.set_title("Late deliveries: NPS proxy of -43 vs +45 on time")
        fig.tight_layout(); fig.savefig(OUT / "chart_nps_delivery.png", dpi=140); plt.close(fig)

    if "q10_cohort_retention" in r:
        d = r["q10_cohort_retention"].set_index("cohort")[["m1_pct", "m3_pct", "m6_pct"]]
        d.columns = ["1 month later", "3 months later", "6 months later"]
        ax = d.plot(figsize=(9, 4.5), marker="o", title="Under 1% of each cohort orders again in any given later month")
        ax.set_ylabel("% of cohort ordering in that month"); ax.set_xlabel("Month of first order")
        ax.set_ylim(0, max(1.0, float(d.max().max()) * 1.2)); ax.grid(axis="y", alpha=0.3)
        ax.figure.tight_layout(); ax.figure.savefig(OUT / "chart_retention.png", dpi=140); plt.close(ax.figure)

if __name__ == "__main__":
    main()
