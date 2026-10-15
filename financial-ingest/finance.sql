-- Challenge: Financial data ingest (live crypto prices from Binance, polled every 2s by crypto_pipeline.py)
SELECT hypertable_name, num_chunks FROM timescaledb_information.hypertables WHERE hypertable_name='crypto_ticks';
SELECT symbol, count(*) ticks, min(time) first_tick, max(time) last_tick FROM crypto_ticks GROUP BY 1 ORDER BY 1;
DROP MATERIALIZED VIEW IF EXISTS crypto_ohlcv_1m CASCADE;
CREATE MATERIALIZED VIEW crypto_ohlcv_1m WITH (timescaledb.continuous) AS
SELECT time_bucket('1 minute', time) AS bucket, symbol,
       first(price, time) AS open, max(price) AS high, min(price) AS low, last(price, time) AS close, count(*) AS ticks
FROM crypto_ticks GROUP BY 1, 2 WITH NO DATA;
CALL refresh_continuous_aggregate('crypto_ohlcv_1m', NULL, NULL);
SELECT add_continuous_aggregate_policy('crypto_ohlcv_1m', start_offset => INTERVAL '1 hour', end_offset => INTERVAL '1 minute', schedule_interval => INTERVAL '1 minute');
ALTER MATERIALIZED VIEW crypto_ohlcv_1m SET (timescaledb.materialized_only = false);
SELECT bucket AT TIME ZONE 'Asia/Kolkata' AS bucket_ist, open, high, low, close, ticks FROM crypto_ohlcv_1m WHERE symbol='BTCUSDT' ORDER BY bucket;
SELECT symbol, round(100*(last(close,bucket)/first(open,bucket)-1),4) AS pct_change, sum(ticks) ticks FROM crypto_ohlcv_1m GROUP BY 1 ORDER BY 2 DESC;
