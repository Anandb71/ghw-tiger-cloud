-- Challenge: Financial data ingest (tick data via COPY + OHLCV candlesticks)
DROP MATERIALIZED VIEW IF EXISTS stock_candlestick_daily CASCADE; DROP TABLE IF EXISTS stocks_real_time CASCADE; DROP TABLE IF EXISTS company;
CREATE TABLE company (symbol TEXT PRIMARY KEY, name TEXT);
INSERT INTO company VALUES ('RELIANCE','Reliance Industries'),('TCS','Tata Consultancy Services'),
 ('INFY','Infosys'),('HDFCBANK','HDFC Bank'),('AAPL','Apple Inc.'),('NVDA','NVIDIA Corp.');
CREATE TABLE stocks_real_time (time TIMESTAMPTZ NOT NULL, symbol TEXT NOT NULL, price DOUBLE PRECISION, day_volume BIGINT)
 WITH (tsdb.hypertable, tsdb.partition_column='time', tsdb.segmentby='symbol');
\copy stocks_real_time FROM 'ticks.csv' WITH (FORMAT csv, HEADER true)
SELECT count(*) ticks, count(DISTINCT symbol) symbols, min(time), max(time) FROM stocks_real_time;
CREATE MATERIALIZED VIEW stock_candlestick_daily WITH (timescaledb.continuous) AS
SELECT time_bucket('1 day', time) AS bucket_day, symbol, first(price,time) open, max(price) high, min(price) low,
       last(price,time) close, last(day_volume,time) volume
FROM stocks_real_time GROUP BY 1,2;
SELECT bucket_day::date AS day, symbol, round(open::numeric,2) open, round(high::numeric,2) high, round(low::numeric,2) low,
       round(close::numeric,2) close, volume FROM stock_candlestick_daily WHERE symbol='RELIANCE' ORDER BY bucket_day DESC LIMIT 7;
-- daily return % per symbol, last day
SELECT symbol, c.name, round((100*(last(price,time)/first(price,time)-1))::numeric,2) pct_change_30d
FROM stocks_real_time JOIN company c USING (symbol) GROUP BY 1,2 ORDER BY 3 DESC;
