class Bank_account
  def initialize(id, name, iban, balance, interest, unlock_date, locked)
    @id = id
    @name = name
    @iban = iban
    @balance = balance
    @interest = interest
    @unlock_date = unlock_date
    @locked = locked
  end

  def create_from_hash(**bank_account)
    @id = bank_account["id"]
    @name = bank_account["name"]
    @iban = bank_account["iban"]
    @balance = bank_account["balance"]
    @interest = bank_account["interest"]
    @unlock_date = bank_account["unlock_date"]
    @locked = bank_account["locked"]
  end
end