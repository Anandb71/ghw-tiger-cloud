# Minimal MCP stdio client talking to `tiger mcp start`
import json, subprocess, sys
p = subprocess.Popen(["tiger","mcp","start"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
i=0
def rpc(method, params=None, notify=False):
    global i
    msg={"jsonrpc":"2.0","method":method,"params":params or {}}
    if not notify: i+=1; msg["id"]=i
    p.stdin.write(json.dumps(msg)+"\n"); p.stdin.flush()
    if notify: return
    while True:
        r=json.loads(p.stdout.readline())
        if r.get("id")==i: return r
rpc("initialize",{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"ghw-client","version":"1"}})
rpc("notifications/initialized",notify=True)
tools=rpc("tools/list")["result"]["tools"]
print("MCP tools:", ", ".join(t["name"] for t in tools))
for name,args in json.loads(sys.argv[1]):
    print(f"\n>>> tools/call {name} {json.dumps(args)}")
    r=rpc("tools/call",{"name":name,"arguments":args})
    for c in r.get("result",{}).get("content",[]): print(c.get("text","")[:3000])
    if "error" in r: print("ERROR", r["error"])
p.terminate()
