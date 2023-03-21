class Loan
  def initialize(loan_as_hash)
    @id = loan_as_hash["id"]
    @size = loan_as_hash["size"]
    @amount_payed = loan_as_hash["amount_payed"]
    @start_time = loan_as_hash["start_time"]
    @interest = loan_as_hash["interest"]
  end

  def print
    puts "Loan"
    puts "id: #{@id}"
    puts "size: #{@size}"
    puts "amount_payed: #{@amount_payed}"
    puts "start_time: #{@start_time}"
    puts "interest: #{@interest}"
  end
end