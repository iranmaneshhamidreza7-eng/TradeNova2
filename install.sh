#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "🚀 شروع ساخت TradeNova2..."

mkdir -p database api components pages admin

cat > config.js <<'FILE'
const CONFIG = {
  APP_NAME: "TradeNova",
  MODE: "demo",
  VERSION: "2.0.0",
  DEFAULT_LANGUAGE: "auto",
  DEFAULT_CURRENCY: "USDT",
  EXCHANGE_RATE: 95000,
  RECEIPT_BOT: "@TradeNovaReceiptBot",
  ADMIN_TELEGRAM: "@Autotradingasbot"
};
FILE

cat > index.html <<'FILE'
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>TradeNova</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<div id="app"></div>

<script src="config.js"></script>
<script src="database/database.js"></script>
<script src="api/api.js"></script>
<script src="components/header.js"></script>
<script src="components/navbar.js"></script>
<script src="components/cards.js"></script>
<script src="components/trades.js"></script>
<script src="components/wallet.js"></script>
<script src="pages/dashboard.js"></script>
<script src="pages/trades.js"></script>
<script src="pages/wallet.js"></script>
<script src="pages/more.js"></script>
<script src="script.js"></script>
</body>
</html>
FILE

cat > database/database.js <<'FILE'
const TradeNovaDB = (() => {
  const state = {
    settings: {
      subscriptionSystem: true,
      defaultSubscriptionPrice: 10,
      globalBotEnabled: true,
      maintenanceMode: false,
      payment: {
        cardNumber: "0000-0000-0000-0000",
        cardOwner: "TradeNova",
        receiptTelegram: "@TradeNovaReceiptBot",
        receiptRubika: ""
      }
    },

    users: {
      demo_iran: {
        id:"demo_iran",
        name:"کاربر ایرانی",
        username:"iran_user",
        country:"Iran",
        language:"fa",
        balance:100,
        totalProfit:246.82,
        todayProfit:18.43,
        botEnabled:true,
        foreverFree:false,
        subscription:{
          active:true,
          expiresAt:"2099-12-31T23:59:59.000Z",
          customPrice:null,
          freeThisPeriod:false
        }
      },

      demo_spain: {
        id:"demo_spain",
        name:"Spanish User",
        username:"spain_user",
        country:"Spain",
        language:"es",
        balance:100,
        totalProfit:120.4,
        todayProfit:7.2,
        botEnabled:true,
        foreverFree:true,
        subscription:{
          active:true,
          expiresAt:null,
          customPrice:null,
          freeThisPeriod:false
        }
      }
    },

    receipts:[]
  };

  const save = () =>
    localStorage.setItem(
      "tradenova_v2",
      JSON.stringify(state)
    );

  const load = () => {
    try {
      const x =
        JSON.parse(
          localStorage.getItem("tradenova_v2")
        );

      if(x) Object.assign(state,x);

    } catch(e){}
  };

  load();

  function getUser(id){
    return state.users[String(id)] || null;
  }

  function getUsers(){
    return Object.values(state.users);
  }

  function updateUser(id,changes={}){
    const u=getUser(id);
    if(!u)return null;

    Object.keys(changes).forEach(k=>{
      if(
        changes[k] &&
        typeof changes[k]==="object" &&
        !Array.isArray(changes[k])
      ){
        u[k]={
          ...(u[k]||{}),
          ...changes[k]
        };
      }else{
        u[k]=changes[k];
      }
    });

    save();
    return u;
  }

  function subscriptionValid(id){
    const u=getUser(id);
    if(!u)return false;

    if(u.foreverFree)return true;
    if(u.subscription.freeThisPeriod)return true;

    return !!(
      u.subscription.active &&
      u.subscription.expiresAt &&
      new Date(u.subscription.expiresAt)>new Date()
    );
  }

  function price(id){
    const u=getUser(id);

    return u?.subscription?.customPrice ??
      state.settings.defaultSubscriptionPrice;
  }

  function updateReceipt(id,changes){
    const r=state.receipts.find(x=>x.id===id);
    if(!r)return null;

    Object.assign(r,changes);
    save();

    return r;
  }

  return {
    state,
    getUser,
    getUsers,
    updateUser,
    subscriptionValid,
    price,
    updateReceipt,

    get receipts(){
      return state.receipts;
    },

    get settings(){
      return state.settings;
    },

    save
  };

})();
FILE

cat > api/api.js <<'FILE'
const TradeNovaAPI = {
  getUsers: async()=>TradeNovaDB.getUsers(),

  getUser: async id=>
    TradeNovaDB.getUser(id),

  updateUser: async(id,c)=>
    TradeNovaDB.updateUser(id,c),

  getReceipts: async()=>
    TradeNovaDB.receipts,

  updateReceipt: async(id,c)=>
    TradeNovaDB.updateReceipt(id,c),

  getSettings: async()=>
    TradeNovaDB.settings
};
FILE

cat > components/header.js <<'FILE'
function renderHeader(user){
  return `
  <header class="topbar">
    <div>
      <h1>TradeNova</h1>
      <small>${user.name}</small>
    </div>
    <div>
      ${
        TradeNovaDB.subscriptionValid(user.id)
        ? "🟢"
        : "🔴"
      }
    </div>
  </header>`;
}
FILE

cat > components/navbar.js <<'FILE'
function renderNavbar(active){
  return `
  <nav class="navbar">

    <button onclick="navigate('dashboard')">
      🏠<span>داشبورد</span>
    </button>

    <button onclick="navigate('trades')">
      📈<span>معاملات</span>
    </button>

    <button onclick="navigate('wallet')">
      💰<span>کیف پول</span>
    </button>

    <button onclick="navigate('more')">
      ⚙️<span>بیشتر</span>
    </button>

  </nav>`;
}
FILE

cat > components/cards.js <<'FILE'
function renderDashboardCards(user){
  return `
  <section class="cards">

    <div class="card">
      <span>موجودی</span>
      <strong>${user.balance.toFixed(2)} USDT</strong>
    </div>

    <div class="card">
      <span>سود امروز</span>
      <strong>+${user.todayProfit.toFixed(2)} USDT</strong>
    </div>

    <div class="card">
      <span>سود کل</span>
      <strong>+${user.totalProfit.toFixed(2)} USDT</strong>
    </div>

  </section>`;
}
FILE

cat > components/trades.js <<'FILE'
function renderTrades(){

  const trades=[
    ["BTC/USDT","BUY","+4.32"],
    ["ETH/USDT","SELL","+7.15"],
    ["SOL/USDT","BUY","+2.81"],
    ["XRP/USDT","SELL","+4.15"]
  ];

  return `
  <section class="panel">
    <h2>📊 معاملات اخیر</h2>

    ${trades.map(t=>`
      <div class="trade">
        <b>${t[0]}</b>
        <span>${t[1]}</span>
        <strong>${t[2]} USDT</strong>
      </div>
    `).join("")}

  </section>`;
}
FILE

cat > components/wallet.js <<'FILE'
function renderWallet(user){

  return `
  <section class="panel wallet">

    <h2>💰 کیف پول</h2>

    <div class="balance">
      ${user.balance.toFixed(2)} USDT
    </div>

    <small>
      ${(user.balance*CONFIG.EXCHANGE_RATE)
      .toLocaleString()} تومان
    </small>

    <button class="primary"
      onclick="alert('نسخه Demo؛ واریز واقعی فعال نیست')">
      ➕ واریز
    </button>

    <button
      onclick="alert('نسخه Demo؛ برداشت واقعی فعال نیست')">
      📤 برداشت
    </button>

  </section>`;
}
FILE

cat > pages/dashboard.js <<'FILE'
function pageDashboard(user){

  return `
  ${renderHeader(user)}

  <main>

    <h2>داشبورد</h2>

    ${renderDashboardCards(user)}

    <section class="panel">

      <h2>🤖 وضعیت ربات</h2>

      <p>
      ${
        user.botEnabled
        ? "🟢 ربات فعال است"
        : "🔴 ربات غیرفعال است"
      }
      </p>

    </section>

    ${renderTrades()}

  </main>

  ${renderNavbar("dashboard")}`;
}
FILE

cat > pages/trades.js <<'FILE'
function pageTrades(user){

  return `
  ${renderHeader(user)}

  <main>
    <h2>📈 معاملات</h2>
    ${renderTrades()}
  </main>

  ${renderNavbar("trades")}`;
}
FILE

cat > pages/wallet.js <<'FILE'
function pageWallet(user){

  return `
  ${renderHeader(user)}

  <main>
    ${renderWallet(user)}
  </main>

  ${renderNavbar("wallet")}`;
}
FILE

cat > pages/more.js <<'FILE'
function pageMore(user){

  const valid =
    TradeNovaDB.subscriptionValid(user.id);

  return `
  ${renderHeader(user)}

  <main>

    <h2>⚙️ بیشتر</h2>

    <section class="panel">

      <button class="menu-btn">
        ${
          valid
          ? "🟢 اشتراک فعال"
          : "🔴 اشتراک منقضی شده"
        }
      </button>

      ${
        !valid
        ? `
        <button
          class="menu-btn primary"
          onclick="showSubscription()">
          💳 خرید اشتراک
        </button>`
        : ""
      }

      <button
        class="menu-btn"
        onclick="openReceiptBot()">
        📤 ارسال رسید
      </button>

      <button
        class="menu-btn"
        onclick="alert('TradeNova 2.0 Demo')">
        ℹ️ درباره TradeNova
      </button>

    </section>

  </main>

  ${renderNavbar("more")}`;
}

function openReceiptBot(){

  const bot =
    TradeNovaDB.settings.payment.receiptTelegram;

  location.href =
    "https://t.me/" +
    bot.replace("@","");
}

function showSubscription(){

  const p =
    TradeNovaDB.settings.payment;

  alert(
`اشتراک ماهانه: ${TradeNovaDB.price("demo_iran")} USD

شماره کارت:
${p.cardNumber}

به نام:
${p.cardOwner}

بعد از پرداخت، رسید را برای ربات ارسال کنید.`
  );
}
FILE

cat > script.js <<'FILE'
let currentUserId="demo_iran";

function getCurrentUser(){
  return TradeNovaDB.getUser(currentUserId);
}

function navigate(page){

  const user=getCurrentUser();

  if(!user)return;

  const app=document.getElementById("app");

  if(page==="dashboard")
    app.innerHTML=pageDashboard(user);

  if(page==="trades")
    app.innerHTML=pageTrades(user);

  if(page==="wallet")
    app.innerHTML=pageWallet(user);

  if(page==="more")
    app.innerHTML=pageMore(user);
}

document.addEventListener(
  "DOMContentLoaded",
  ()=>{
    navigate("dashboard");
  }
);
FILE

cat > style.css <<'FILE'
*{
  box-sizing:border-box;
}

body{
  margin:0;
  font-family:Arial,Tahoma,sans-serif;
  background:#07111f;
  color:white;
  direction:rtl;
}

.topbar{
  display:flex;
  justify-content:space-between;
  align-items:center;
  padding:18px;
  background:#0c1b30;
  border-bottom:1px solid #203654;
}

.topbar h1{
  margin:0;
  color:#38bdf8;
}

.topbar small{
  color:#9db1c7;
}

main{
  padding:18px;
  padding-bottom:100px;
}

.cards{
  display:grid;
  grid-template-columns:repeat(3,1fr);
  gap:10px;
}

.card{
  background:#0d2038;
  padding:15px;
  border-radius:15px;
}

.card span{
  display:block;
  color:#9db1c7;
}

.card strong{
  display:block;
  margin-top:10px;
  color:#4ade80;
}

.panel{
  background:#0c1b30;
  border:1px solid #203654;
  border-radius:16px;
  padding:16px;
  margin-top:15px;
}

.trade{
  display:grid;
  grid-template-columns:1fr 1fr 1fr;
  padding:13px 0;
  border-bottom:1px solid #203654;
}

.trade span{
  color:#38bdf8;
}

.trade strong{
  color:#4ade80;
}

.navbar{
  position:fixed;
  bottom:0;
  left:0;
  right:0;
  display:grid;
  grid-template-columns:repeat(4,1fr);
  background:#0a1728;
  border-top:1px solid #203654;
  padding:8px;
}

.navbar button{
  background:transparent;
  border:0;
  color:#9db1c7;
  padding:8px;
}

.navbar span{
  display:block;
  font-size:11px;
}

.menu-btn,
.primary{
  width:100%;
  border:0;
  border-radius:12px;
  padding:14px;
  margin-top:10px;
  background:#132944;
  color:white;
}

.primary{
  background:#0284c7;
}

.wallet{
  text-align:center;
}

.balance{
  font-size:36px;
  font-weight:bold;
  color:#4ade80;
  margin:25px 0 10px;
}

@media(max-width:600px){

  .cards{
    grid-template-columns:1fr;
  }

}
FILE

cat > admin/index.html <<'FILE'
<!DOCTYPE html>
<html lang="fa" dir="rtl">

<head>
<meta charset="UTF-8">
<meta name="viewport"
content="width=device-width,initial-scale=1">
<title>TradeNova Admin</title>
<link rel="stylesheet" href="admin.css">
</head>

<body>

<div id="admin"></div>

<script src="../config.js"></script>
<script src="../database/database.js"></script>
<script src="../api/api.js"></script>
<script src="admin.js"></script>

</body>
</html>
FILE

cat > admin/admin.js <<'FILE'
const Admin={

  render:async()=>{

    const users=
      await TradeNovaAPI.getUsers();

    const receipts=
      await TradeNovaAPI.getReceipts();

    const s=
      TradeNovaDB.settings;

    document.getElementById("admin").innerHTML=`

    <header>
      <h1>TradeNova Admin</h1>
      <a href="../index.html">
      ↩️ مینی‌اپ
      </a>
    </header>

    <section class="stats">

      <div>
        کاربران
        <strong>${users.length}</strong>
      </div>

      <div>
        رسیدهای در انتظار
        <strong>
        ${receipts.filter(
          r=>r.status==="pending"
        ).length}
        </strong>
      </div>

      <div>
        ربات
        <strong>
        ${s.globalBotEnabled?"فعال":"غیرفعال"}
        </strong>
      </div>

    </section>

    <section>

      <h2>⚙️ تنظیمات پرداخت</h2>

      <label>
        شماره کارت
        <input id="card"
        value="${s.payment.cardNumber}">
      </label>

      <label>
        صاحب کارت
        <input id="owner"
        value="${s.payment.cardOwner}">
      </label>

      <label>
        ربات رسید
        <input id="receipt"
        value="${s.payment.receiptTelegram}">
      </label>

      <button onclick="saveSettings()">
      💾 ذخیره
      </button>

    </section>

    <section>

      <h2>👥 کاربران</h2>

      ${users.map(u=>`

        <article>

          <b>${u.name}</b>

          <span>
          @${u.username}
          — ${u.country}
          </span>

          <p>
          اشتراک:
          ${
            TradeNovaDB.subscriptionValid(u.id)
            ?"🟢 فعال"
            :"🔴 منقضی"
          }
          </p>

          <button
          onclick="freeUser('${u.id}')">
          🎁 این ماه رایگان
          </button>

          <button
          onclick="foreverUser('${u.id}')">
          ♾️ همیشه رایگان
          </button>

          <button
          onclick="toggleBot('${u.id}')">
          ${u.botEnabled
            ?"🔴 غیرفعال کردن"
            :"🟢 فعال کردن"}
          ربات
          </button>

        </article>

      `).join("")}

    </section>

    <section>

      <h2>📤 رسیدها</h2>

      ${
        receipts.length
        ? receipts.map(r=>`

          <article>

            <b>${r.id}</b>

            <span>
            کاربر: ${r.userId}
            </span>

            <p>
            وضعیت: ${r.status}
            </p>

            ${
              r.status==="pending"
              ?`
              <button
              onclick="approve('${r.id}')">
              ✅ تایید
              </button>

              <button
              onclick="reject('${r.id}')">
              ❌ رد
              </button>`
              :""
            }

          </article>

        `).join("")
        :"<p>رسیدی وجود ندارد.</p>"
      }

    </section>
    `;
  }
};

function saveSettings(){

  TradeNovaDB.settings.payment.cardNumber=
    document.getElementById("card").value;

  TradeNovaDB.settings.payment.cardOwner=
    document.getElementById("owner").value;

  TradeNovaDB.settings.payment.receiptTelegram=
    document.getElementById("receipt").value;

  TradeNovaDB.save();

  alert("ذخیره شد");

  Admin.render();
}

function freeUser(id){

  TradeNovaDB.updateUser(id,{
    subscription:{
      freeThisPeriod:true
    }
  });

  Admin.render();
}

function foreverUser(id){

  TradeNovaDB.updateUser(id,{
    foreverFree:true
  });

  Admin.render();
}

function toggleBot(id){

  const u=TradeNovaDB.getUser(id);

  TradeNovaDB.updateUser(id,{
    botEnabled:!u.botEnabled
  });

  Admin.render();
}

function approve(id){

  TradeNovaDB.updateReceipt(id,{
    status:"approved",
    reviewedAt:
      new Date().toISOString()
  });

  Admin.render();
}

function reject(id){

  TradeNovaDB.updateReceipt(id,{
    status:"rejected",
    reviewedAt:
      new Date().toISOString()
  });

  Admin.render();
}

Admin.render();
FILE

cat > admin/admin.css <<'FILE'
*{
  box-sizing:border-box;
}

body{
  margin:0;
  background:#07111f;
  color:white;
  font-family:Arial,Tahoma,sans-serif;
  direction:rtl;
}

header{
  padding:20px;
  background:#0c1b30;
  display:flex;
  justify-content:space-between;
  align-items:center;
}

header h1{
  color:#38bdf8;
}

header a{
  color:white;
}

section{
  margin:15px;
  padding:18px;
  background:#0c1b30;
  border:1px solid #203654;
  border-radius:16px;
}

.stats{
  display:grid;
  grid-template-columns:repeat(3,1fr);
  gap:10px;
}

.stats div{
  padding:15px;
  background:#10253e;
  border-radius:12px;
}

.stats strong{
  display:block;
  color:#4ade80;
  margin-top:8px;
}

article{
  padding:15px;
  margin-top:10px;
  background:#10253e;
  border-radius:12px;
}

article span{
  display:block;
  color:#9db1c7;
  margin-top:5px;
}

label{
  display:block;
  margin:12px 0;
}

input{
  display:block;
  width:100%;
  padding:12px;
  margin-top:5px;
  border-radius:8px;
  border:1px solid #294766;
  background:#07111f;
  color:white;
}

button{
  padding:10px 14px;
  margin:5px;
  border:0;
  border-radius:8px;
  background:#087ea8;
  color:white;
}

@media(max-width:600px){

  .stats{
    grid-template-columns:1fr;
  }

}
FILE

echo ""
echo "===================================="
echo "✅ TradeNova2 ساخته شد!"
echo "===================================="
echo ""
echo "برای اجرای آزمایشی:"
echo "python -m http.server 8000"
echo ""
echo "مینی‌اپ:"
echo "http://127.0.0.1:8000"
echo ""
echo "پنل مدیریت:"
echo "http://127.0.0.1:8000/admin/"
echo ""

