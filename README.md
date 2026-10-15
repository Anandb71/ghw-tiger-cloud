# GHW Hacktoberfest 2026 – Tiger Cloud (TimescaleDB) challenges

All scripts were run against a live Tiger Cloud service (`ghw-tiger`, AWS Mumbai). Each folder has the SQL, the captured output (`*_output.txt`) and a rendered screenshot (`*_output.png`).

| Challenge | Folder | What it does |
|---|---|---|
| CLI / MCP | `cli-mcp/` | Tiger CLI login with client credentials, `tiger service list`/`get`; Tiger MCP server (`tiger mcp start`) driven over JSON-RPC: `service_list` and `db_query` returning live row counts and hypertable chunks |
| Hypertable | `hypertable/` | `conditions` hypertable (1-day chunks, segment by location), 16k weather rows across 4 Indian cities, chunk inspection, `time_bucket` daily averages |
| IoT simulation | `iot-simulation/` | 50 simulated devices × 7 days @ 1-minute = 504,050 readings (daily temperature cycle, noise, rare spikes, battery drain, error statuses); latest-per-device, 3σ anomaly detection, error rate per site |
| Continuous aggregates | `continuous-aggregates/` | `iot_hourly` continuous aggregate + refresh policy (every 30 min) + real-time aggregation, queried and EXPLAINed |
| Financial ingest | `financial-ingest/` | `gen_ticks.py` simulates 30 days of trade ticks (GBM) for 6 symbols → 691,100 rows bulk-loaded with COPY into `stocks_real_time` hypertable; daily OHLCV candlestick continuous aggregate with `first()/last()` |
| pgvector | `pgvector/` | `vector` extension, 384-dim embeddings (all-MiniLM-L6-v2) for 10 docs, HNSW cosine index, semantic nearest-neighbour search |

Run: `python run.py <folder>/<script>.sql` with `TIGER_DSN` set (a small psql-style runner using psycopg; `psql -f` also works from inside each folder).
