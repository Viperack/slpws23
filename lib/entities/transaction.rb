class Transaction
  attr_reader :id, :sender_id, :receiver_id, :size, :time

  def initialize(transaction_as_hash)
    @id = transaction_as_hash["id"]
    @sender_id = transaction_as_hash["sender_id"]
    @receiver_id = transaction_as_hash["receiver_id"]
    @size = transaction_as_hash["size"]
    @time = transaction_as_hash["time"]
  end

  def print
    puts "Transaction"
    puts "id: #{@id}"
    puts "sender_id: #{@sender_id}"
    puts "receiver_id: #{@receiver_id}"
    puts "size: #{@size}"
    puts "time: #{@time}"
  end
end