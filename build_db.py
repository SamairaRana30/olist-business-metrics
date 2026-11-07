"""Step 1: load the Olist CSVs from ./data into a SQLite file (olist.db).

Download the dataset from Kaggle ("Brazilian E-Commerce Public Dataset by Olist"),
unzip the CSVs into the data/ folder, then run:   python build_db.py
Optional: also drop the "Marketing Funnel by Olist" CSVs into data/ for the MQL funnel query.
"""
import sqlite3, sys
from pathlib import Path
import pandas as pd

DATA = Path(__file__).parent / "data"
DB = Path(__file__).parent / "olist.db"

# filename fragment -> table name, expected rows in the full Kaggle files (None = don't check)
TABLES = {
    "olist_customers_dataset": ("customers", 99441),
    "olist_orders_dataset": ("orders", 99441),
    "olist_order_items_dataset": ("order_items", 112650),
    "olist_order_payments_dataset": ("order_payments", 103886),
    "olist_order_reviews_dataset": ("order_reviews", 99224),
    "olist_products_dataset": ("products", 32951),
    "olist_sellers_dataset": ("sellers", 3095),  # not used by the queries; loaded for extra questions
    "product_category_name_translation": ("category_translation", 71),
    "olist_marketing_qualified_leads_dataset": ("mqls", 8000),
    "olist_closed_deals_dataset": ("closed_deals", 842),
}

def main():
    if not DATA.exists() or not list(DATA.glob("*.csv")):
        sys.exit("No CSV files in data/. Put the Olist CSVs there first.")
    if DB.exists():
        DB.unlink()
    con = sqlite3.connect(DB)
    loaded = 0
    for frag, (table, expected) in TABLES.items():
        files = list(DATA.glob(f"{frag}*.csv"))
        if not files:
            note = "  (optional)" if table in ("mqls", "closed_deals", "sellers") else "  <-- MISSING"
            print(f"{table:22s} not found{note}")
            continue
        df = pd.read_csv(files[0])          # empty cells become NULL in SQLite
        df.to_sql(table, con, index=False)
        flag = "" if expected is None or len(df) == expected else f"  (full dataset has {expected}: check the file)"
        print(f"{table:22s} {len(df):>8,} rows{flag}")
        loaded += 1
    con.execute("CREATE INDEX IF NOT EXISTS ix_items_order ON order_items(order_id)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_pay_order ON order_payments(order_id)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_rev_order ON order_reviews(order_id)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_ord_cust ON orders(customer_id)")
    con.commit(); con.close()
    print(f"\nDone: {loaded} tables in {DB.name}. Next: python run_metrics.py")

if __name__ == "__main__":
    main()
