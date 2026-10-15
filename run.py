# Minimal psql-like runner: python run.py <script.sql>  (reads DSN from env TIGER_DSN)
import os, re, sys, time, psycopg
path = sys.argv[1]; base = os.path.dirname(os.path.abspath(path))
vars_ = {}
def show(cur):
    if cur.description is None: print(cur.statusmessage); return
    cols=[d.name for d in cur.description]; rows=[[("" if v is None else str(v)) for v in r] for r in cur.fetchall()]
    w=[max([len(c)]+[len(r[i]) for r in rows]) for i,c in enumerate(cols)]
    print(" | ".join(c.ljust(w[i]) for i,c in enumerate(cols))); print("-+-".join("-"*x for x in w))
    for r in rows: print(" | ".join(v.ljust(w[i]) for i,v in enumerate(r)))
    print(f"({len(rows)} row{'s' if len(rows)!=1 else ''})\n")
with psycopg.connect(os.environ["TIGER_DSN"], autocommit=True) as conn:
    buf=""
    for line in open(path, encoding="utf-8"):
        s=line.strip()
        if s.startswith("\\copy"):
            m=re.match(r"\\copy (\S+(?: \([^)]*\))?) FROM '([^']+)' WITH \((.*)\)", s)
            t0=time.time(); n=0
            with conn.cursor() as cur, cur.copy(f"COPY {m[1]} FROM STDIN WITH ({m[3]})") as cp:
                with open(os.path.join(base,m[2]),"rb") as f:
                    while chunk:=f.read(1<<20): cp.write(chunk)
            print(f"=> {s}\nCOPY done in {time.time()-t0:.1f}s\n"); continue
        if s.startswith("\\set"):
            _,k,v=s.split(None,2); vars_[k]=open(os.path.join(base,v.strip('`').split()[1])).read().strip(); continue
        if s.startswith("--") or not s: 
            if s.startswith("--") and not buf: print(s)
            continue
        buf+=line
        if s.endswith(";") or re.search(r";\s*--.*$",s):
            sql=buf
            for k,v in vars_.items(): sql=sql.replace(f":'{k}'", "'"+v+"'")
            short = buf.strip() if len(buf)<400 else buf.strip()[:400]+"..."
            print("=> "+short)
            with conn.cursor() as cur:
                cur.execute(sql); show(cur)
            buf=""
