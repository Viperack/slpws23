class Loan
  def initialize(id, size, amount_payed, start_time, interest)
    @id = id
    @size = size
    @amount_payed = amount_payed
    @start_time = start_time
    @interest = interest
  end

  def create_from_hash(**loan)
    @id = loan["id"]
    @size = loan["size"]
    @amount_payed = loan["amount_payed"]
    @start_time = loan["start_time"]
    @interest = loan["interest"]
  end

end