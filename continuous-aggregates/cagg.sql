-- Challenge: Continuous Aggregates (on iot_readings)
DROP MATERIALIZED VIEW IF EXISTS iot_hourly CASCADE;
CREATE MATERIALIZED VIEW iot_hourly WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket, device_id,
       avg(temperature) avg_temp, max(temperature) max_temp, min(battery) min_battery, count(*) n
FROM iot_readings GROUP BY 1,2 WITH NO DATA;
SELECT add_continuous_aggregate_policy('iot_hourly', start_offset => INTERVAL '3 days',
  end_offset => INTERVAL '1 hour', schedule_interval => INTERVAL '30 minutes');
CALL refresh_continuous_aggregate('iot_hourly', NULL, now() - interval '1 hour');
ALTER MATERIALIZED VIEW iot_hourly SET (timescaledb.materialized_only = false); -- real-time aggregation
SELECT view_name, materialized_only FROM timescaledb_information.continuous_aggregates;
SELECT job_id, proc_name, schedule_interval FROM timescaledb_information.jobs WHERE proc_name LIKE '%continuous%';
SELECT bucket, device_id, round(avg_temp::numeric,2) avg_temp, round(max_temp::numeric,2) max_temp, n
FROM iot_hourly WHERE device_id=1 ORDER BY bucket DESC LIMIT 8;
EXPLAIN (ANALYZE, TIMING OFF) SELECT device_id, avg(avg_temp) FROM iot_hourly GROUP BY 1;
