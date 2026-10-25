function renderNavbar(active){
  const items=[
    ['dashboard','⌂','داشبورد'],
    ['trades','↗','معاملات'],
    ['wallet','₮','کیف پول'],
    ['more','⚙','تنظیمات']
  ];

  return `<nav class="navbar glass-nav">${items.map(x=>`
    <button class="${active===x[0]?'active':''}" onclick="navigate('${x[0]}')">
      <span class="nav-icon">${x[1]}</span>
      <span>${x[2]}</span>
    </button>`).join('')}</nav>`;
}
