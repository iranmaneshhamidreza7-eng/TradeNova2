/* Live USD-to-Toman display rate. Fetched from our same-origin Python endpoint. */
(function(){
  const FALLBACK = Number(CONFIG.EXCHANGE_RATE) || 267700;
  const state = { rate: FALLBACK, source: 'نرخ پیش‌فرض', updatedAt: null, live: false };
  let lastAttempt = 0;
  let pending = null;

  function isIranianUser(user){
    const country = String(user && user.country || '').trim().toLowerCase();
    if (country) return ['iran','ir','iran, islamic republic of'].includes(country);
    const userLang = String(user && user.language || '').toLowerCase();
    const tgLang = String(window.Telegram?.WebApp?.initDataUnsafe?.user?.language_code || '').toLowerCase();
    const browserLang = String(navigator.language || '').toLowerCase();
    return userLang.startsWith('fa') || tgLang.startsWith('fa') || browserLang.startsWith('fa');
  }

  function formatToman(amount){
    return Math.round(Number(amount) || 0).toLocaleString('en-US');
  }

  async function refresh(force=false){
    const now = Date.now();
    if (!force && now - lastAttempt < 60000) return state;
    if (pending) return pending;
    lastAttempt = now;
    pending = (async()=>{
      try {
        const res = await fetch('/api/rate', {cache:'no-store', headers:{'Accept':'application/json'}});
        if (!res.ok) throw new Error('Rate endpoint HTTP ' + res.status);
        const data = await res.json();
        const rate = Number(data && data.usdToman);
        if (!Number.isFinite(rate) || rate < 1000 || rate > 10000000) throw new Error('Invalid USD/Toman rate');
        state.rate = rate;
        state.source = data.source || 'Arzbin';
        state.updatedAt = data.updatedAt || new Date().toISOString();
        state.live = true;
        CONFIG.EXCHANGE_RATE = rate;
        window.dispatchEvent(new Event('tradenova:rate-updated'));
      } catch (e) {
        state.live = false;
        state.source = 'نرخ ذخیره‌شده (اتصال به منبع برقرار نشد)';
        console.warn('TradeNova rate update failed; keeping last known rate.', e);
      } finally { pending = null; }
      return state;
    })();
    return pending;
  }

  function tomanLine(user){
    if (!isIranianUser(user)) return '';
    const status = state.live ? 'نرخ بازار آزاد' : 'نرخ ذخیره‌شده';
    return `<div class="rate-caption">${status} · منبع: Arzbin · هر دلار: ${formatToman(state.rate)} تومان</div>`;
  }

  window.TradeNovaRates = {state, refresh, isIranianUser, formatToman, tomanLine};
  refresh();
  setInterval(()=>refresh(true), 5 * 60 * 1000);
})();
