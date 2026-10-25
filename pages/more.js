function pageMore(user){
  const valid=TradeNovaDB.subscriptionValid(user.id);
  const mode=TradeNovaDB.settings.tradingMode==='live';

  return `
  ${renderHeader(user)}
  <main class="settings-page">
    <section class="settings-head"><span class="eyebrow">حساب کاربری</span><h2>تنظیمات</h2><p>مدیریت اشتراک، امنیت و وضعیت ربات</p></section>

    <section class="settings-card mode-card">
      <div class="settings-row">
        <div class="settings-leading mode-leading"><span>⚡</span></div>
        <div class="settings-copy"><strong>حالت معاملات</strong><small>${mode?'واقعی':'آزمایشی'} · ${mode?'Live':'Demo'}</small></div>
        <span class="pill ${mode?'pill-red':'pill-blue'}">${mode?'LIVE':'DEMO'}</span>
      </div>
      <p class="settings-note">تغییر به حالت واقعی فقط وقتی سفارش ارسال می‌کند که اتصال امن صرافی و مجوزهای لازم فعال باشند.</p>
    </section>

    <section class="settings-card">
      <div class="settings-section-title">اشتراک</div>
      <div class="settings-row"><div class="settings-leading">${valid?'🟢':'🔴'}</div><div class="settings-copy"><strong>${valid?'اشتراک فعال':'اشتراک منقضی شده'}</strong><small>${valid?'دسترسی ربات برقرار است':'برای ادامه اشتراک تهیه کنید'}</small></div>${!valid?'<button class="settings-small-btn" onclick="showSubscription()">خرید</button>':''}</div>
      <button class="settings-menu" onclick="openReceiptBot()"><span>📤</span><div><strong>ارسال رسید</strong><small>ارسال رسید پرداخت به ربات</small></div><b>‹</b></button>
    </section>

    <section class="settings-card">
      <div class="settings-section-title">عمومی</div>
      <button class="settings-menu" onclick="changeCountry()"><span>🌍</span><div><strong>کشور</strong><small>${user.country||'نامشخص'} · مبنای نمایش ارز محلی</small></div><b>‹</b></button><button class="settings-menu" onclick="alert('زبان رابط بر اساس زبان تلگرام/گوشی انتخاب می‌شود.')"><span>🌐</span><div><strong>زبان</strong><small>${user.language==='fa'?'فارسی':(user.language||'auto')}</small></div><b>‹</b></button>
      <button class="settings-menu" onclick="alert('TradeNova Demo v3.1')"><span>ⓘ</span><div><strong>درباره TradeNova</strong><small>نسخه 3.1 Demo</small></div><b>‹</b></button>
    </section>

    <section class="settings-security"><span>🔐</span><div><strong>امنیت اولویت TradeNova است</strong><p>کلیدهای صرافی و اطلاعات حساس نباید داخل Mini App ذخیره شوند.</p></div></section>
  </main>
  ${renderNavbar('more')}`;
}

function openReceiptBot(){const bot=TradeNovaDB.settings.payment.receiptTelegram;location.href='https://t.me/'+bot.replace('@','');}
function showSubscription(){const p=TradeNovaDB.settings.payment;alert(`اشتراک ماهانه: ${TradeNovaDB.price('demo_iran')} USD\n\nشماره کارت:\n${p.cardNumber}\n\nبه نام:\n${p.cardOwner}\n\nبعد از پرداخت، رسید را برای ربات ارسال کنید.`);}

function changeCountry(){const u=getCurrentUser();const v=prompt('کد کشور یا نام کشور را وارد کن (Iran, Spain, United States و ...):',u.country||'Unknown');if(v===null)return;TradeNovaDB.updateUser(u.id,{country:v.trim()||'Unknown'});navigate('more');}
