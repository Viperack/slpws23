class Bank_account
  attr_reader :id, :name, :iban, :balance, :interest, :unlock_date, :locked

  def initialize(bank_account_as_hash)
    @id = bank_account_as_hash["id"]
    @name = bank_account_as_hash["name"]
    @iban = bank_account_as_hash["iban"]
    @balance = bank_account_as_hash["balance"]
    @interest = bank_account_as_hash["interest"]
    @unlock_date = bank_account_as_hash["unlock_date"]
    @locked = bank_account_as_hash["locked"]
  end

  def print
    puts "Bank_account"
    puts "id: #{@id}"
    puts "name: #{@name}"
    puts "iban: #{@iban}"
    puts "balance: #{@balance}"
    puts "interest: #{@interest}"
    puts "unlock_date: #{@unlock_date}"
    puts "locked: #{@locked}"
  end
end