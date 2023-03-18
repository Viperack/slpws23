class Transaction
  def initialize(id, sender_id, receiver_id, size, time)
    @id = id
    @sender_id = sender_id
    @receiver_id = receiver_id
    @size = size
    @time = time
  end

  def create_from_hash(**transaction)
    @id = transaction["id"]
    @sender_id = transaction["sender_id"]
    @receiver_id = transaction["receiver_id"]
    @size = transaction["size"]
    @time = transaction["time"]
  end
end