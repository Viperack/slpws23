class User
  attr_reader :id, :name, :email, :password_digest, :permission_level
  def initialize(user_as_hash)
    @id = user_as_hash["id"]
    @name = user_as_hash["name"]
    @email = user_as_hash["email"]
    @password_digest = user_as_hash["password_digest"]
    @permission_level = user_as_hash["permission_level"]
  end

  def print
    puts "USER"
    puts "id: #{@id}"
    puts "name: #{@name}"
    puts "email: #{@email}"
    puts "password_digest: #{@password_digest}"
    puts "permission_level: #{@permission_level}"
  end
end