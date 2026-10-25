function pageDashboard(user){

  const profitPercent =
    user.balance > 0
      ? ((user.todayProfit / user.balance) * 100).toFixed(2)
      : "0.00";

  return `
  ${renderHeader(user)}

  <main class="dashboard">

    <section class="hero-card">

      <div class="hero-top">
        <div>
          <span class="muted">ارزش کل دارایی</span>

          <div class="main-balance">
            ${user.balance.toFixed(2)}
            <small>USDT</small>
          </div>

          ${TradeNovaRates.isIranianUser(user) ? `
          <div class="tomans">
            ≈ ${TradeNovaRates.formatToman(user.balance * TradeNovaRates.state.rate)} تومان
          </div>
          ${TradeNovaRates.tomanLine(user)}` : ''}
        </div>

        <div class="balance-icon">
          ₮
        </div>
      </div>

      <div class="profit-row">

        <div>
          <span>سود امروز</span>
          <strong class="green">
            +${user.todayProfit.toFixed(2)} USDT
          </strong>
        </div>

        <div class="profit-percent">
          +${profitPercent}%
        </div>

      </div>

    </section>


    <section class="quick-grid">

      <div class="stat-card">

        <div class="stat-icon green-bg">
          ↗
        </div>

        <div>
          <span>سود کل</span>
          <strong>
            +${user.totalProfit.toFixed(2)}
          </strong>
          <small>USDT</small>
        </div>

      </div>


      <div class="stat-card">

        <div class="stat-icon blue-bg">
          ◉
        </div>

        <div>
          <span>معاملات امروز</span>
          <strong>${(window.TradeNovaBot?.readTrades?.()||[]).filter(t=>new Date(t.createdAt||0).toDateString()===new Date().toDateString()).length}</strong>
          <small>معامله</small>
        </div>

      </div>

    </section>


    <section class="chart-panel">

      <div class="section-title">

        <div>
          <h2>📈 عملکرد</h2>
          <span>سود ۷ روز اخیر</span>
        </div>

        <button class="period-btn">
          ۷ روزه ▾
        </button>

      </div>


      <div class="chart">

        <div class="chart-grid"></div>

        <div class="chart-line">

          <span class="point p1"></span>
          <span class="point p2"></span>
          <span class="point p3"></span>
          <span class="point p4"></span>
          <span class="point p5"></span>
          <span class="point p6"></span>
          <span class="point p7"></span>

        </div>

      </div>

      <div class="chart-days">
        <span>شنبه</span>
        <span>یکشنبه</span>
        <span>دوشنبه</span>
        <span>سه‌شنبه</span>
        <span>چهارشنبه</span>
        <span>پنجشنبه</span>
        <span>جمعه</span>
      </div>

    </section>


    <section class="bot-card">

      <div class="bot-main">

        <div class="bot-logo">
          🤖
        </div>

        <div>

          <h2>ربات معامله‌گر</h2>

          <p>
            ${
              user.botEnabled
              ? "در حال بررسی بازار و آماده معامله"
              : "ربات در حال حاضر غیرفعال است"
            }
          </p>

        </div>

      </div>


      <div class="bot-status">

        <span class="status-dot ${
          user.botEnabled ? "online" : "offline"
        }"></span>

        ${
          user.botEnabled
          ? "فعال"
          : "غیرفعال"
        }

      </div>

    </section>


    <section class="recent-panel">

      <div class="section-title">

        <div>
          <h2>معاملات اخیر</h2>
          <span>آخرین فعالیت‌ها</span>
        </div>

        <button
          class="view-all"
          onclick="navigate('trades')">
          مشاهده همه
        </button>

      </div>

      ${renderProfessionalTrades()}

    </section>


    <section class="security-card">

      <div class="security-icon">
        🛡️
      </div>

      <div>

        <strong>امنیت حساب</strong>

        <p>
          حساب شما با حالت Demo محافظت می‌شود.
        </p>

      </div>

      <span class="secure-label">
        امن
      </span>

    </section>

  </main>

  ${renderNavbar("dashboard")}
  `;
}


function renderProfessionalTrades(){
  const trades = (window.TradeNovaBot?.readTrades?.() || []).slice(0,3);
  if (!trades.length) return `<div class="empty-state">ربات هنوز در این حساب معاملهٔ آزمایشی نبسته است؛ پس از دریافت سیگنال معتبر، نتیجه اینجا نمایش داده می‌شود.</div>`;
  return `<div class="professional-trades">${trades.map(t=>`
    <div class="professional-trade">
      <div class="coin-icon">${t.icon || "₿"}</div>
      <div class="trade-info"><strong>${t.pair}</strong><span>${t.type==="BUY"?"خرید":"فروش"} · ${t.time||""} · آزمایشی</span></div>
      <div class="trade-profit" style="color:${Number(t.profit)>=0?'var(--green)':'var(--red)'}">${Number(t.profit)>=0?"+":""}${Number(t.profit).toFixed(4)} USDT</div>
    </div>`).join("")}</div>`;
}
