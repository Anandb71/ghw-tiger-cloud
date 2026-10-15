# Pulls real Hacker News story titles (Algolia API) from the last 6 weeks, 5 categories
import json, urllib.request, urllib.parse, time, csv
from urllib.parse import urlparse
cats = {"ai":["AI","LLM"],"databases":["database","Postgres","SQL"],"security":["security","vulnerability"],"space":["space","NASA"],"crypto":["bitcoin","crypto","ethereum"]}
now = int(time.time()); start = now - 42*86400; rows=[]; seen=set()
for cat,qs in cats.items():
  for q in qs:
    for w in range(6):  # one request per week window for spread
        a, b = start + w*7*86400, start + (w+1)*7*86400
        url = "https://hn.algolia.com/api/v1/search?" + urllib.parse.urlencode({"query":q,"tags":"story","numericFilters":f"created_at_i>{a},created_at_i<{b},points>3","hitsPerPage":8})
        for h in json.load(urllib.request.urlopen(url, timeout=15))["hits"]:
            if h["objectID"] in seen or not h.get("title"): continue
            seen.add(h["objectID"])
            src = urlparse(h.get("url") or "").netloc.removeprefix("www.") or "news.ycombinator.com"
            rows.append((h["created_at"], src, cat, h["title"]))
with open("headlines_raw.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["time","source","category","title"]); w.writerows(rows)
print(len(rows), "headlines")
