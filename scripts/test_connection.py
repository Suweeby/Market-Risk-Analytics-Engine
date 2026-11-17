import pandas as pd
from sqlalchemy import text
from src.db import get_engine

engine = get_engine()

# 1. Can we reach the server?
with engine.connect() as conn:
    print(conn.execute(text("SELECT version();")).scalar())

# 2. Can pandas write a table?
df = pd.DataFrame({"symbol": ["RELIANCE", "TCS"], "close": [2900.50, 4100.00]})
df.to_sql("_smoke_test", engine, if_exists="replace", index=False)

# 3. Can pandas read it back?
print(pd.read_sql("SELECT * FROM _smoke_test", engine))

# 4. Clean up
with engine.begin() as conn:
    conn.execute(text("DROP TABLE _smoke_test"))

print("Setup OK")