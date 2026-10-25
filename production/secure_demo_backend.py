"""Optional server-side paper trading API. Python standard library only.
Never accepts user IDs from client; Telegram initData HMAC is verified server-side.
Not a real exchange, financial service, or production-ready deployment.
"""
import hashlib, hmac, json, os, random, sqlite3, threading, time, urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

DB = Path(os.environ.get('TRADENOVA_DB_PATH', str(Path(__file__).resolve().parent / 'demo.sqlite3')))
TOKEN = os.environ.get('TRADENOVA_BOT_TOKEN', '')
HOST = os.environ.get('TRADENOVA_HOST', '127.0.0.1')
PORT = int(os.environ.get('TRADENOVA_API_PORT', '8765'))
LOCK = threading.RLock()
PAIRS = ['BTC/USDT', 'ETH/USDT', 'SOL/USDT', 'XRP/USDT']
PRICES = {'BTC/USDT': 68000., 'ETH/USDT': 3800., 'SOL/USDT': 185., 'XRP/USDT': 2.4}

def connect():
    DB.parent.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(DB, timeout=10)
    c.row_factory = sqlite3.Row
    return c

def init_db():
    with connect() as c:
        c.executescript('''
        CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY, name TEXT NOT NULL, balance REAL NOT NULL DEFAULT 0, bot_enabled INTEGER NOT NULL DEFAULT 0, subscription_until INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS trades(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL, pair TEXT NOT NULL, side TEXT NOT NULL, entry REAL NOT NULL, exit REAL NOT NULL, amount REAL NOT NULL, fee REAL NOT NULL, profit REAL NOT NULL, closed_at INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS positions(user_id TEXT PRIMARY KEY, pair TEXT NOT NULL, side TEXT NOT NULL, entry REAL NOT NULL, amount REAL NOT NULL, opened_at INTEGER NOT NULL);
        ''')

def verify_init_data(raw):
    if not TOKEN or not isinstance(raw, str) or len(raw) > 8192: raise ValueError('Telegram bot token not configured or bad initData')
    pairs = urllib.parse.parse_qsl(raw, keep_blank_values=True, strict_parsing=True)
    data = dict(pairs)
    if len(data) != len(pairs) or 'hash' not in data or 'auth_date' not in data or 'user' not in data: raise ValueError('Invalid Telegram initData')
    ts = int(data['auth_date'])
    if abs(time.time() - ts) > 3600: raise ValueError('Expired Telegram initData')
    check = '\n'.join(f'{k}={v}' for k,v in sorted(data.items()) if k not in ('hash','signature'))
    secret = hmac.new(b'WebAppData', TOKEN.encode(), hashlib.sha256).digest()
    expected = hmac.new(secret, check.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, data['hash']): raise ValueError('Telegram signature invalid')
    user = json.loads(data['user'])
    if not isinstance(user, dict) or not isinstance(user.get('id'), int): raise ValueError('Missing Telegram user')
    return user

def ensure_user(user):
    uid = str(user['id']); name = str(user.get('first_name') or 'User')[:120]
    with connect() as c:
        c.execute('INSERT OR IGNORE INTO users(id,name,created_at) VALUES(?,?,?)', (uid,name,int(time.time())))
        c.execute('UPDATE users SET name=? WHERE id=?', (name,uid))
    return uid

def snapshot(uid):
    with connect() as c:
        u = c.execute('SELECT * FROM users WHERE id=?',(uid,)).fetchone()
        trades = [dict(x) for x in c.execute('SELECT * FROM trades WHERE user_id=? ORDER BY id DESC LIMIT 50',(uid,))]
    return {'user':dict(u),'trades':trades,'mode':'PAPER','prices':'synthetic'}

def verify_admin(raw):
    user = verify_init_data(raw)
    allowed = {x.strip() for x in os.environ.get('TRADENOVA_ADMIN_IDS','').split(',') if x.strip()}
    if str(user['id']) not in allowed:
        raise ValueError('Not authorized as admin')
    return user

def admin_state():
    with connect() as c:
        users = [dict(x) for x in c.execute('SELECT id,name,balance,bot_enabled,subscription_until,created_at FROM users ORDER BY created_at DESC LIMIT 500')]
        counts = c.execute('SELECT COUNT(*) AS n FROM trades').fetchone()['n']
    return {'mode':'PAPER','users':users,'total_trades':counts,'note':'Server-side demo users only'}

def admin_action(data):
    if not isinstance(data,dict): raise ValueError('Invalid request')
    uid=str(data.get('user_id',''))
    if not uid.isdigit() or len(uid)>30: raise ValueError('Invalid user ID')
    action=data.get('action')
    if action not in ('enable_bot','disable_bot','activate_month','disable_subscription'):
        raise ValueError('Unsupported action')
    now=int(time.time())
    with LOCK, connect() as c:
        if not c.execute('SELECT 1 FROM users WHERE id=?',(uid,)).fetchone(): raise ValueError('User not found')
        if action in ('enable_bot','disable_bot'):
            c.execute('UPDATE users SET bot_enabled=? WHERE id=?',(int(action=='enable_bot'),uid))
        elif action=='activate_month':
            current=c.execute('SELECT subscription_until FROM users WHERE id=?',(uid,)).fetchone()['subscription_until']
            c.execute('UPDATE users SET subscription_until=? WHERE id=?',(max(now,current)+30*86400,uid))
        else:
            c.execute('UPDATE users SET subscription_until=0,bot_enabled=0 WHERE id=?',(uid,))
    return {'ok':True,'user_id':uid,'action':action}

def tick():
    now = int(time.time())
    with LOCK:
        for pair in PAIRS: PRICES[pair] *= 1 + random.uniform(-0.003, 0.003)
        with connect() as c:
            for u in c.execute('SELECT * FROM users WHERE bot_enabled=1 AND subscription_until>? AND balance>1',(now,)).fetchall():
                uid = u['id']; pos = c.execute('SELECT * FROM positions WHERE user_id=?',(uid,)).fetchone()
                if pos:
                    current = PRICES[pos['pair']]; change = (current-pos['entry'])/pos['entry'] * (1 if pos['side']=='BUY' else -1)
                    if abs(change) >= 0.006 or now-pos['opened_at'] >= 90:
                        gross = (current-pos['entry'])*pos['amount']*(1 if pos['side']=='BUY' else -1)
                        fee = (current+pos['entry'])*pos['amount']*0.001
                        pnl = round(gross-fee, 6)
                        c.execute('INSERT INTO trades(user_id,pair,side,entry,exit,amount,fee,profit,closed_at) VALUES(?,?,?,?,?,?,?,?,?)',(uid,pos['pair'],pos['side'],pos['entry'],current,pos['amount'],fee,pnl,now))
                        c.execute('UPDATE users SET balance=MAX(0,balance+?) WHERE id=?',(pnl,uid))
                        c.execute('DELETE FROM positions WHERE user_id=?',(uid,))
                else:
                    pair = random.choice(PAIRS); entry=PRICES[pair]; amount=min(u['balance']*.1,10)/entry
                    c.execute('INSERT INTO positions VALUES(?,?,?,?,?,?)',(uid,pair,random.choice(['BUY','SELL']),entry,amount,now))

def loop():
    while True:
        try: tick()
        except Exception as e: print('Paper tick error:', repr(e),flush=True)
        time.sleep(15)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health': return self.respond(200,{'ok':True,'mode':'PAPER','backend':'SQLite'})
        if self.path != '/api/me': return self.respond(404,{'error':'Not found'})
        self.authorized()
    def authorized(self):
        try:
            raw = self.headers.get('X-Telegram-Init-Data','')
            uid = ensure_user(verify_init_data(raw))
            self.respond(200,snapshot(uid))
        except (ValueError, TypeError, KeyError, json.JSONDecodeError) as e:
            self.respond(401,{'error':str(e)})
    def respond(self,status,data):
        body=json.dumps(data,ensure_ascii=False).encode()
        self.send_response(status);self.send_header('Content-Type','application/json; charset=utf-8');self.send_header('Cache-Control','no-store');self.send_header('X-Content-Type-Options','nosniff');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body)

if __name__=='__main__':
    init_db()
    if not TOKEN: print('WARNING: TRADENOVA_BOT_TOKEN missing; authenticated API requests will fail.',flush=True)
    threading.Thread(target=loop,daemon=True).start()
    print(f'Secure demo backend: http://{HOST}:{PORT} (PAPER ONLY)',flush=True)
    ThreadingHTTPServer((HOST,PORT),Handler).serve_forever()
