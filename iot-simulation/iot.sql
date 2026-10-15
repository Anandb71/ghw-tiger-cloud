-- Challenge: IoT data simulation (50 devices, 7 days @ 1-minute)
DROP TABLE IF EXISTS iot_readings CASCADE; DROP TABLE IF EXISTS devices CASCADE;
CREATE TABLE devices (device_id INT PRIMARY KEY, kind TEXT, site TEXT);
INSERT INTO devices SELECT i, (ARRAY['thermostat','air_quality','power_meter'])[1+i%3],
  (ARRAY['factory-a','factory-b','warehouse','office'])[1+i%4] FROM generate_series(1,50) i;
CREATE TABLE iot_readings (
  time TIMESTAMPTZ NOT NULL, device_id INT NOT NULL REFERENCES devices,
  temperature DOUBLE PRECISION, humidity DOUBLE PRECISION, battery DOUBLE PRECISION, status TEXT
) WITH (tsdb.hypertable, tsdb.partition_column='time', tsdb.segmentby='device_id');
INSERT INTO iot_readings
SELECT t, d,
  20 + d%7 + 5*sin(extract(epoch FROM t)/86400*2*pi()) + (random()-0.5)*1.5
     + CASE WHEN random() < 0.001 THEN 25 ELSE 0 END,           -- rare spikes
  45 + 10*random(),
  greatest(0, 100 - extract(epoch FROM (t - (now()-interval '7 days')))/86400 * (2 + d%5)),
  CASE WHEN random() < 0.002 THEN 'error' ELSE 'ok' END
FROM generate_series(now()-interval '7 days', now(), interval '1 minute') t, generate_series(1,50) d;
SELECT count(*) readings, count(DISTINCT device_id) devices FROM iot_readings;
-- latest reading per device
SELECT DISTINCT ON (device_id) device_id, time, round(temperature::numeric,1) temp, round(battery::numeric,1) battery
FROM iot_readings ORDER BY device_id, time DESC LIMIT 5;
-- anomaly detection: temperature spikes > 3 sigma per device
WITH s AS (SELECT device_id, avg(temperature) m, stddev(temperature) sd FROM iot_readings GROUP BY 1)
SELECT r.time, r.device_id, round(r.temperature::numeric,1) temp
FROM iot_readings r JOIN s USING (device_id) WHERE r.temperature > s.m + 3*s.sd ORDER BY r.time DESC LIMIT 10;
-- error rate by site
SELECT d.site, count(*) FILTER (WHERE status='error') errors, round(100.0*count(*) FILTER (WHERE status='error')/count(*),3) pct
FROM iot_readings r JOIN devices d USING (device_id) GROUP BY 1 ORDER BY 1;
