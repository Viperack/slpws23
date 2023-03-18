class User
  def initialize(id, name, email, password_digest)
    @id = id
    @name = name
    @email = email
    @password_digest = password_digest
  end

  def create_from_hash(**user)
    @id = user["id"]
    @name = user["name"]
    @email = user["email"]
    @password_digest = user["password_digest"]
  end
end