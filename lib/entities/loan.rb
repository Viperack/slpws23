class Loan
  attr_reader :id, :size, :amount_payed, :interest_payment_date, :interest

  def initialize(loan_as_hash)
    @id = loan_as_hash["id"]
    @size = loan_as_hash["size"]
    @amount_payed = loan_as_hash["amount_payed"]
    @interest_payment_date = loan_as_hash["interest_payment_date"]
    @interest = loan_as_hash["interest"]
  end

  def print
    puts "Loan"
    puts "id: #{@id}"
    puts "size: #{@size}"
    puts "amount_payed: #{@amount_payed}"
    puts "interest_payment_date: #{@interest_payment_date}"
    puts "interest: #{@interest}"
  end
end