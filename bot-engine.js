/* TradeNova PAPER-TRADING ENGINE
 * This browser-side engine is for simulation only. It does not send real orders.
 * Real automated trading must run server-side with an approved broker/exchange connector,
 * authenticated users, risk limits, and audited order/fill records.
 */
const TradeNovaBot = (() => {
  let timer = null;
  const pairs = ["BTC/USDT", "ETH/USDT", "SOL/USDT", "XRP/USDT"];
  const initial = {"BTC/USDT":68000,"ETH/USDT":3800,"SOL/USDT":185,"XRP/USDT":2.4};
  const icons = {"BTC/USDT":"₿","ETH/USDT":"Ξ","SOL/USDT":"S","XRP/USDT":"X"};
  const prices = {...initial};
  const ticks = Object.fromEntries(pairs.map(p => [p, []]));
  const positions = {};
  const lastEntry = {};
  const FEE_RATE = 0.001; // simulated 0.1% per side
  const MAX_EXPOSURE_FRACTION = 0.10;
  const COOLDOWN_MS = 45000;
  const TICK_MS = 15000;

  const userId = () => String(window.TradeNovaCurrentUserId || "demo_iran");
  const key = () => `tradenova_paper_trades_${userId()}`;
  const readTrades = () => { try { return JSON.parse(localStorage.getItem(key()) || "[]"); } catch (_) { return []; } };
  const saveTrades = trades => localStorage.setItem(key(), JSON.stringify(trades.slice(0,100)));
  function tradingMode() { return window.TradeNovaDB?.settings?.tradingMode || "demo"; }
  function canTrade() {
    const user = window.TradeNovaDB?.getUser?.(userId());
    const settings = window.TradeNovaDB?.settings;
    return !!(tradingMode() === "demo" && user && settings?.globalBotEnabled && !settings?.maintenanceMode && user.botEnabled && window.TradeNovaDB.subscriptionValid(user.id));
  }
  function tickPrices() {
    // Synthetic price movements only; these are deliberately not represented as exchange quotes.
    for (const pair of pairs) {
      const history = ticks[pair];
      const previous = prices[pair];
      const shock = (Math.random() - 0.49) * (pair === "BTC/USDT" ? 0.004 : pair === "XRP/USDT" ? 0.009 : 0.006);
      const next = Math.max(previous * 0.8, previous * (1 + shock));
      prices[pair] = next;
      history.push({price: next, at: Date.now()});
      if (history.length > 12) history.shift();
    }
  }
  function makeTrade(pair, side, entry, exit, amount, openedAt) {
    const gross = side === "BUY" ? (exit - entry) * amount : (entry - exit) * amount;
    const fees = (entry * amount + exit * amount) * FEE_RATE;
    const pnl = gross - fees;
    const trade = {
      id: "TN-PAPER-" + Date.now().toString(36).toUpperCase() + "-" + Math.random().toString(36).slice(2,5).toUpperCase(),
      userId: userId(), pair, icon: icons[pair], type: side, entry, current: exit, amount,
      profit: Number(pnl.toFixed(6)), fees: Number(fees.toFixed(6)), status: "CLOSED",
      openedAt: new Date(openedAt).toISOString(), createdAt: new Date().toISOString(),
      time: new Date().toLocaleTimeString("fa-IR"), mode: "PAPER", strategy: "Momentum + risk limits"
    };
    const trades = readTrades(); trades.unshift(trade); saveTrades(trades);
    const user = window.TradeNovaDB?.getUser?.(userId());
    if (user) {
      user.balance = Number(Math.max(0, Number(user.balance || 0) + pnl).toFixed(6));
      user.todayProfit = Number((Number(user.todayProfit || 0) + pnl).toFixed(6));
      user.totalProfit = Number((Number(user.totalProfit || 0) + pnl).toFixed(6));
      window.TradeNovaDB.save();
    }
    window.dispatchEvent(new CustomEvent("tradenova:new-trade", {detail: trade}));
    window.dispatchEvent(new CustomEvent("tradenova:data-updated", {detail: trade}));
    return trade;
  }
  function evaluatePositions() {
    for (const pair of pairs) {
      const pos = positions[pair]; if (!pos) continue;
      const current = prices[pair];
      const move = pos.side === "BUY" ? (current - pos.entry) / pos.entry : (pos.entry - current) / pos.entry;
      const held = Date.now() - pos.openedAt;
      if (move >= 0.008 || move <= -0.006 || held >= 90000) {
        makeTrade(pair, pos.side, pos.entry, current, pos.amount, pos.openedAt);
        delete positions[pair];
      }
    }
  }
  function evaluateEntries() {
    if (!canTrade()) return;
    const user = window.TradeNovaDB.getUser(userId());
    const balance = Number(user.balance || 0);
    if (balance <= 1) return;
    for (const pair of pairs) {
      if (positions[pair] || Date.now() - (lastEntry[pair] || 0) < COOLDOWN_MS) continue;
      const history = ticks[pair]; if (history.length < 5) continue;
      const short = history.slice(-2).reduce((s,x)=>s+x.price,0)/2;
      const long = history.slice(-5).reduce((s,x)=>s+x.price,0)/5;
      const momentum = (short-long)/long;
      if (Math.abs(momentum) < 0.00035) continue;
      const side = momentum > 0 ? "BUY" : "SELL";
      const entry = prices[pair];
      const notional = Math.min(balance * MAX_EXPOSURE_FRACTION, 10);
      const amount = notional / entry;
      positions[pair] = {side, entry, amount, openedAt: Date.now()};
      lastEntry[pair] = Date.now();
      window.dispatchEvent(new CustomEvent("tradenova:position-opened", {detail:{pair,side,entry,mode:"PAPER"}}));
      // One new position per tick to avoid opening several positions at once.
      break;
    }
  }
  function run(force=false) {
    if (tradingMode() === "live") {
      window.dispatchEvent(new CustomEvent("tradenova:live-blocked", {detail:{reason:"exchange_connector_missing"}}));
      return null;
    }
    tickPrices(); evaluatePositions();
    if (force) {
      // Manual button intentionally does not fabricate a trade; the strategy acts on its next valid signal.
      evaluateEntries();
      return {status:"strategy_tick", mode:"PAPER"};
    }
    evaluateEntries();
    return {status:"tick", mode:"PAPER"};
  }
  function start() { if (timer) return; tickPrices(); timer = setInterval(run, TICK_MS); run(); }
  function stop() { if (timer) { clearInterval(timer); timer = null; } }
  function status() { return {mode:tradingMode(),running:!!timer,positions:Object.entries(positions).map(([pair,p])=>({pair,...p})),tradeCount:readTrades().length}; }
  return {start, stop, run, readTrades, status};
})();
