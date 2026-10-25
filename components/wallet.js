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
