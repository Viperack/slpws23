class Interest
  def initialize(id, interest, time_deposit, type)
    @id = id
    @interest = interest
    @time_deposit = time_deposit
    @type = type
  end

  def create_from_hash(**interest)
    @id = interest["id"]
    @interest = interest["interest"]
    @time_deposit = interest["time_deposit"]
    @type = interest["type"]
  end
end