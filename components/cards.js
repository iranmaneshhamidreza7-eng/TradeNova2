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
