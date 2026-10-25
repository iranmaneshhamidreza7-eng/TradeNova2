const TradeNovaAPI = {
  getUsers: async()=>TradeNovaDB.getUsers(),

  getUser: async id=>
    TradeNovaDB.getUser(id),

  updateUser: async(id,c)=>
    TradeNovaDB.updateUser(id,c),

  getReceipts: async()=>
    TradeNovaDB.receipts,

  getMoneyRequests: async()=>TradeNovaDB.moneyRequests,

  reviewMoneyRequest: async(id,action,note='')=>TradeNovaDB.reviewMoneyRequest(id,action,note),

  updateReceipt: async(id,c)=>
    TradeNovaDB.updateReceipt(id,c),

  getSettings: async()=>
    TradeNovaDB.settings
};
