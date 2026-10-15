# Builds 384-dim embeddings with a local sentence-transformer (all-MiniLM-L6-v2)
import csv, sys
from sentence_transformers import SentenceTransformer
m = SentenceTransformer('all-MiniLM-L6-v2')
docs = [
 ("Hypertables","Hypertables automatically partition time-series data into chunks by time."),
 ("Continuous aggregates","Continuous aggregates incrementally refresh materialized rollups like hourly averages."),
 ("Compression","Columnar compression reduces storage for old time-series chunks by over 90 percent."),
 ("pgvector","pgvector stores embeddings and supports nearest neighbour similarity search in Postgres."),
 ("IoT sensors","IoT devices stream temperature, humidity and battery readings every minute."),
 ("Stock candlesticks","OHLC candlestick charts summarize open, high, low and close prices for a stock."),
 ("Hacktoberfest","Hacktoberfest is a month-long celebration of open source contributions in October."),
 ("Kerala food","Appam with stew and Kerala parotta with beef fry are popular dishes in Kochi."),
 ("Cricket","India won the match after a brilliant century from the opening batsman."),
 ("Retention policies","Data retention policies automatically drop chunks older than a set interval."),
]
E = m.encode([t+". "+b for t,b in docs], normalize_embeddings=True)
with open('docs.csv','w',newline='') as f:
    w=csv.writer(f); w.writerow(['title','body','embedding'])
    for (t,b),e in zip(docs,E): w.writerow([t,b,'['+','.join(f'{x:.6f}' for x in e)+']'])
q = sys.argv[1] if len(sys.argv)>1 else "how do I search embeddings for similar text in a database"
open('query_vec.txt','w').write('['+','.join(f'{x:.6f}' for x in m.encode(q, normalize_embeddings=True))+']')
open('query.txt','w').write(q)
