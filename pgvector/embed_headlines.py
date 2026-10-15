# Embeds headlines + search queries with all-MiniLM-L6-v2 (384 dims, normalized)
import csv
from sentence_transformers import SentenceTransformer
m = SentenceTransformer("all-MiniLM-L6-v2")
rows = list(csv.DictReader(open("headlines_raw.csv")))
E = m.encode([r["title"] for r in rows], normalize_embeddings=True, batch_size=64)
vec = lambda e: "[" + ",".join(f"{x:.6f}" for x in e) + "]"
with open("headlines.csv","w",newline="") as f:
    w = csv.writer(f); w.writerow(["time","source","category","title","embedding"])
    for r,e in zip(rows,E): w.writerow([r["time"], r["source"], r["category"], r["title"], vec(e)])
queries = {"q1":"large language model agents writing code", "q2":"hackers exploit a critical vulnerability", "q3":"rocket launch to the moon"}
for k,q in queries.items():
    open(f"{k}_vec.txt","w").write(vec(m.encode(q, normalize_embeddings=True)))
open("queries.txt","w").write("\n".join(f"{k}: {q}" for k,q in queries.items()))
