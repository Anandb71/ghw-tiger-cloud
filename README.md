# GHW Hacktoberfest 2026 – Tiger Cloud (TimescaleDB) challenges

All scripts were run against a live Tiger Cloud service (`ghw-tiger`, AWS Mumbai). Each folder has the SQL, the captured output (`*_output.txt`) and a rendered screenshot (`*_output.png`).

| Challenge | Folder | What it does |
|---|---|---|
| CLI / MCP | `cli-mcp/` | Tiger CLI login with client credentials, `tiger service list`/`get`; Tiger MCP server (`tiger mcp start`) driven over JSON-RPC: `service_list` and `db_query` returning live row counts and hypertable chunks |
| Hypertable | `hypertable/` | `conditions` hypertable (1-day chunks, segment by location), 16k weather rows across 4 Indian cities, chunk inspection, `time_bucket` daily averages |
| IoT simulation | `iot-simulation/` | 50 simulated devices × 7 days @ 1-minute = 504,050 readings (daily temperature cycle, noise, rare spikes, battery drain, error statuses); latest-per-device, 3σ anomaly detection, error rate per site |
| Continuous aggregates | `continuous-aggregates/` | `iot_hourly` continuous aggregate + refresh policy (every 30 min) + real-time aggregation, queried and EXPLAINed |
| Financial ingest | `financial-ingest/` | `crypto_pipeline.py`: real-time pipeline polling the live Binance `/api/v3/ticker/price` every 2 s for BTC, ETH, SOL, BNB, XRP, DOGE (9 min, 1,620 ticks on Oct 15 2026) into the `crypto_ticks` hypertable; 1-minute OHLCV continuous aggregate (`first/last/max/min`) with refresh policy + real-time mode |
| pgvector | `pgvector/` | `headlines` **hypertable** (7-day chunks) of 446 real Hacker News headlines (Sep 3 – Oct 14 2026, 5 categories, 286 sources) with 384-dim all-MiniLM-L6-v2 embeddings; `pgvectorscale` **DiskANN** index; similarity search filtered by time range + category/source using cosine `<=>`, L2 `<->` and inner product `<#>` |

Run: `python run.py <folder>/<script>.sql` with `TIGER_DSN` set (a small psql-style runner using psycopg; `psql -f` also works from inside each folder).
