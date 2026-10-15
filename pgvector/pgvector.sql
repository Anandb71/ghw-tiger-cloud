-- Challenge: pgvector semantic search
CREATE EXTENSION IF NOT EXISTS vector;
DROP TABLE IF EXISTS docs;
CREATE TABLE docs (id SERIAL PRIMARY KEY, title TEXT, body TEXT, embedding vector(384));
\copy docs (title, body, embedding) FROM 'docs.csv' WITH (FORMAT csv, HEADER true)
CREATE INDEX ON docs USING hnsw (embedding vector_cosine_ops);
SELECT extname, extversion FROM pg_extension WHERE extname='vector';
SELECT count(*) docs, vector_dims(embedding) dims FROM docs GROUP BY 2;
\set q `cat query_vec.txt`
SELECT id, title, round((1 - (embedding <=> :'q'::vector))::numeric,4) cosine_sim
FROM docs ORDER BY embedding <=> :'q'::vector LIMIT 5;
