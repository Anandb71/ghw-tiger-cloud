# Simulates 30 days of trade ticks (geometric Brownian motion) -> ticks.csv
import csv, random, math, datetime as dt
random.seed(71)
start = {'RELIANCE':2900,'TCS':4100,'INFY':1850,'HDFCBANK':1650,'AAPL':230,'NVDA':135}
now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)
t0 = now - dt.timedelta(days=30)
with open('ticks.csv','w',newline='') as f:
    w = csv.writer(f); w.writerow(['time','symbol','price','day_volume'])
    for s,p in start.items():
        t, vol, day = t0, 0, t0.date()
        while t < now:
            t += dt.timedelta(seconds=random.randint(5,40))
            if t.date()!=day: vol, day = 0, t.date()
            p *= math.exp(random.gauss(0.000002, 0.0009)); vol += random.randint(10,2000)
            w.writerow([t.isoformat(), s, round(p,2), vol])
