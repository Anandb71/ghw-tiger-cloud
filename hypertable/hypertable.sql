-- Challenge: Hypertable
DROP TABLE IF EXISTS conditions CASCADE;
CREATE TABLE conditions (
  time        TIMESTAMPTZ NOT NULL,
  location    TEXT        NOT NULL,
  temperature DOUBLE PRECISION,
  humidity    DOUBLE PRECISION
) WITH (tsdb.hypertable, tsdb.partition_column='time', tsdb.segmentby='location', tsdb.chunk_interval='1 day');

INSERT INTO conditions
SELECT t, loc,
       24 + 6*sin(extract(epoch FROM t)/86400*2*pi()) + random()*2,
       55 + 15*cos(extract(epoch FROM t)/86400*2*pi()) + random()*5
FROM generate_series(now() - interval '14 days', now(), interval '5 minutes') t,
     unnest(ARRAY['mumbai','kochi','bengaluru','delhi']) loc;

SELECT hypertable_name, num_dimensions, num_chunks, compression_enabled
FROM timescaledb_information.hypertables WHERE hypertable_name='conditions';
SELECT count(*) AS rows, min(time), max(time) FROM conditions;
SELECT chunk_name, range_start, range_end FROM timescaledb_information.chunks
WHERE hypertable_name='conditions' ORDER BY range_start LIMIT 5;
SELECT time_bucket('1 day', time) AS day, location, round(avg(temperature)::numeric,2) avg_temp
FROM conditions WHERE location='mumbai' GROUP BY 1,2 ORDER BY 1 DESC LIMIT 7;
