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
