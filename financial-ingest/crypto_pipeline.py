# Real-time pipeline: polls Binance public ticker every ~2s and inserts into hypertable crypto_ticks
import os, sys, time, json, urllib.request, urllib.parse, datetime as dt, psycopg
SYMBOLS = ["BTCUSDT","ETHUSDT","SOLUSDT","BNBUSDT","XRPUSDT","DOGEUSDT"]

URL = "https://api.binance.com/api/v3/ticker/price?symbols=" + urllib.parse.quote(json.dumps(SYMBOLS, separators=(",",":")))
DURATION = int(sys.argv[1]) if len(sys.argv) > 1 else 540
with psycopg.connect(os.environ["TIGER_DSN"], autocommit=True) as conn:
    conn.execute("""CREATE TABLE IF NOT EXISTS crypto_ticks (
        time TIMESTAMPTZ NOT NULL, symbol TEXT NOT NULL, price NUMERIC NOT NULL, source TEXT DEFAULT 'binance')
        WITH (tsdb.hypertable, tsdb.partition_column='time', tsdb.segmentby='symbol', tsdb.chunk_interval='1 hour')""")
    end = time.time() + DURATION; n = 0; polls = 0
    while time.time() < end:
        t0 = time.time()
        try:
            data = json.load(urllib.request.urlopen(URL, timeout=5))
            now = dt.datetime.now(dt.timezone.utc)
            with conn.cursor() as cur:
                cur.executemany("INSERT INTO crypto_ticks (time, symbol, price) VALUES (%s,%s,%s)",
                                [(now, d["symbol"], d["price"]) for d in data])
            n += len(data); polls += 1
            if polls % 30 == 1: print(f"{now.isoformat(timespec='seconds')} poll={polls} rows={n} BTC={next(d['price'] for d in data if d['symbol']=='BTCUSDT')}", flush=True)
        except Exception as e:
            print("poll error:", type(e).__name__, e, flush=True)
        time.sleep(max(0, 2 - (time.time() - t0)))
    print(f"done: {polls} polls, {n} rows inserted", flush=True)
