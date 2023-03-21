class User
  def initialize(**user_as_hash)
    @id = user_as_hash["id"]
    @name = user_as_hash["name"]
    @email = user_as_hash["email"]
    @password_digest = user_as_hash["password_digest"]
  end

  def print
    puts "USER"
    puts "id: #{@id}"
    puts "name: #{@name}"
    puts "email: #{@email}"
    puts "password_digest: #{@password_digest}"
  end
end

user = User.new("id" => 1)

user.print

