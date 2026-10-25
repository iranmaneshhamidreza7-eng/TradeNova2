from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json, os, re, time, urllib.request, urllib.error, sys, threading
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent / "production"))
import secure_demo_backend as paper

ROOT=Path(__file__).resolve().parent
TOKEN=os.environ.get("TRADENOVA_BOT_TOKEN","")
RATE_CACHE={"value":None,"updated":0,"source":"Arzbin"}
RATE_TTL=300
RATE_URLS=["https://www.arzbin.com/history/usd/30-days"]

def fetch_usd_toman():
    now=time.time()
    if RATE_CACHE["value"] and now-RATE_CACHE["updated"] < RATE_TTL:
        return RATE_CACHE["value"], RATE_CACHE["updated"]
    last_error=None
    for url in RATE_URLS:
        try:
            req=urllib.request.Request(url,headers={"User-Agent":"TradeNova/1.0 (rate display)","Accept":"text/html"})
            with urllib.request.urlopen(req,timeout=12) as resp:
                html=resp.read().decode("utf-8","replace")
            # Arzbin's USD history page labels the latest parallel-market quote as "Current".
            plain=re.sub(r"<[^>]+>"," ",html)
            plain=plain.replace("&nbsp;"," ").replace("&#8217;","'")
            plain=re.sub(r"\s+"," ",plain)
            match=re.search(r"Current\s+([0-9,]+)\s+Period High",plain,re.I)
            if not match:
                # Fallback to a common USD-to-Toman rate label if the page layout changes.
                match=re.search(r"USD to Toman.{0,100}?([0-9]{3},[0-9]{3})",plain,re.I)
            if not match:
                raise ValueError("Could not find the current USD/Toman quote on Arzbin")
            value=int(match.group(1).replace(",",""))
            if not 1000 <= value <= 10000000:
                raise ValueError("USD/Toman quote outside expected range")
            RATE_CACHE.update({"value":value,"updated":now,"source":"Arzbin (parallel market, indicative)"})
            return value, now
        except Exception as e:
            last_error=e
    if RATE_CACHE["value"]:
        return RATE_CACHE["value"], RATE_CACHE["updated"]
    raise RuntimeError("Live rate source unavailable: " + str(last_error))

class Handler(SimpleHTTPRequestHandler):
    def do_HEAD(self):
        if self._private_path():
            self.send_error(404)
            return
        return super().do_HEAD()

    def _private_path(self):
        from urllib.parse import unquote, urlsplit
        path = unquote(urlsplit(self.path).path)
        parts = path.replace('\\', '/').split('/')
        blocked = {'.git', '.env', 'production', 'tn-production.env.example', 'render.yaml',
                   'telegram-server.py', 'install.sh', 'START_TERMUX.sh', 'database',
                   '__pycache__', 'README.md', 'RENDER_SETUP_FA.md', 'RUN_IN_TERMUX.fa.md'}
        return any(part.startswith('.') or part in blocked or part.endswith(('.py', '.sqlite3', '.sql', '.sh', '.md', '.bak')) for part in parts if part)

    def do_GET(self):
        if self._private_path():
            return self.send_error(404)
        if self.path.split('?',1)[0] == '/api/admin/state':
            try:
                admin=paper.verify_admin(self.headers.get('X-Telegram-Init-Data',''))
                return self.send_json(200,paper.admin_state())
            except (ValueError, TypeError, KeyError, json.JSONDecodeError):
                return self.send_json(403,{'error':'Admin authorization required'})
        if self.path.split('?',1)[0] == '/api/me':
            try:
                raw=self.headers.get('X-Telegram-Init-Data','')
                uid=paper.ensure_user(paper.verify_init_data(raw))
                return self.send_json(200,paper.snapshot(uid))
            except (ValueError, TypeError, KeyError, json.JSONDecodeError):
                return self.send_json(401,{'error':'Telegram authentication required'})
        if self.path.split('?',1)[0] == '/health':
            return self.send_json(200,{'ok':True,'mode':'PAPER','database':'SQLite'})
        if self.path.split("?",1)[0] == "/api/rate":
            try:
                value, updated = fetch_usd_toman()
                self.send_json(200,{"ok":True,"usdToman":value,"currency":"Toman","source":RATE_CACHE["source"],"updatedAt":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime(updated)),"cacheSeconds":RATE_TTL})
            except Exception as e:
                print("RATE ERROR:",repr(e))
                self.send_json(503,{"ok":False,"error":"live rate unavailable"})
            return
        return super().do_GET()

    def do_POST(self):
        if self.path.split('?',1)[0] != '/api/admin/action':
            return self.send_json(403,{'error':'This endpoint is disabled'})
        try:
            paper.verify_admin(self.headers.get('X-Telegram-Init-Data',''))
            length=int(self.headers.get('Content-Length','0'))
            if not 0 < length <= 2048: return self.send_json(400,{'error':'Invalid body length'})
            payload=json.loads(self.rfile.read(length))
            return self.send_json(200,paper.admin_action(payload))
        except (ValueError, TypeError, KeyError, json.JSONDecodeError) as e:
            return self.send_json(400,{'error':str(e)})
    def send_json(self,status,obj):
        b=json.dumps(obj,ensure_ascii=False).encode(); self.send_response(status); self.send_header("Content-Type","application/json; charset=utf-8"); self.send_header("Cache-Control","no-store"); self.send_header("Access-Control-Allow-Origin","*"); self.end_headers(); self.wfile.write(b)
    def log_message(self,format,*args): print("[HTTP]",format%args)

os.chdir(ROOT)
print("TradeNova server running on http://127.0.0.1:8000")
print("Live rate endpoint: GET /api/rate (Arzbin, cached for 5 minutes)")
paper.init_db()
threading.Thread(target=paper.loop,daemon=True).start()
print("Paper trading API: GET /api/me (Telegram signed initData required)")
ThreadingHTTPServer((os.environ.get("TRADENOVA_HOST", "0.0.0.0"), int(os.environ.get("PORT", "8000"))),Handler).serve_forever()
