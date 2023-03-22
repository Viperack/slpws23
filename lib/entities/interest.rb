class Interest
  attr_reader :id, :rate, :time_deposit, :time_deposit, :type

  def initialize(interest_as_hash)
    @id = interest_as_hash["id"]
    @rate = interest_as_hash["rate"]
    @time_deposit = interest_as_hash["time_deposit"]
    @type = interest_as_hash["type"]
  end

  def print
    puts "Interest"
    puts "id: #{@id}"
    puts "rate: #{@rate}"
    puts "time_deposit: #{@time_deposit}"
    puts "type: #{@type}"
  end
end