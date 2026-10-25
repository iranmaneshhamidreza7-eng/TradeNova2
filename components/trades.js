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
