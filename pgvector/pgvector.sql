-- Challenge: pgvector + pgvectorscale on a hypertable of real, timestamped Hacker News headlines
CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;
SELECT extname, extversion FROM pg_extension WHERE extname IN ('vector','vectorscale','timescaledb') ORDER BY 1;
DROP TABLE IF EXISTS docs;
DROP TABLE IF EXISTS headlines;
CREATE TABLE headlines (
  time      TIMESTAMPTZ NOT NULL,
  source    TEXT NOT NULL,
  category  TEXT NOT NULL,
  title     TEXT NOT NULL,
  embedding vector(384) NOT NULL
) WITH (tsdb.hypertable, tsdb.partition_column='time', tsdb.chunk_interval='7 days');
\copy headlines (time, source, category, title, embedding) FROM 'headlines.csv' WITH (FORMAT csv, HEADER true)
CREATE INDEX headlines_embedding_diskann ON headlines USING diskann (embedding vector_cosine_ops);
SELECT count(*) AS headlines, count(DISTINCT source) AS sources, min(time)::date AS first_day, max(time)::date AS last_day, (SELECT vector_dims(embedding) FROM headlines LIMIT 1) AS dims FROM headlines;
SELECT category, count(*) FROM headlines GROUP BY 1 ORDER BY 1;
SELECT hypertable_name, num_chunks FROM timescaledb_information.hypertables WHERE hypertable_name='headlines';
SELECT indexname, indexdef FROM pg_indexes WHERE indexname LIKE 'headlines_embedding%';
\set q1 `cat q1_vec.txt`
\set q2 `cat q2_vec.txt`
\set q3 `cat q3_vec.txt`
-- Q1 "large language model agents writing code" | cosine distance <=> | last 14 days, category ai
SELECT time::date, source, left(title,70) AS title, round((embedding <=> :'q1'::vector)::numeric,4) AS cosine_dist
FROM headlines WHERE category='ai' AND time > now() - interval '14 days'
ORDER BY embedding <=> :'q1'::vector LIMIT 5;
-- Q2 "hackers exploit a critical vulnerability" | L2 distance <-> | Sep 15 - Oct 5, category security
SELECT time::date, source, left(title,70) AS title, round((embedding <-> :'q2'::vector)::numeric,4) AS l2_dist
FROM headlines WHERE category='security' AND time BETWEEN '2026-09-15' AND '2026-10-05'
ORDER BY embedding <-> :'q2'::vector LIMIT 5;
-- Q3 "rocket launch to the moon" | negative inner product <#> | last 30 days, any category, excluding source github.com
SELECT time::date, category, source, left(title,60) AS title, round((-(embedding <#> :'q3'::vector))::numeric,4) AS inner_product
FROM headlines WHERE time > now() - interval '30 days' AND source <> 'github.com'
ORDER BY embedding <#> :'q3'::vector LIMIT 5;
-- index use for the filtered cosine query
EXPLAIN (COSTS OFF) SELECT title FROM headlines WHERE time > now() - interval '14 days' ORDER BY embedding <=> :'q1'::vector LIMIT 5;
