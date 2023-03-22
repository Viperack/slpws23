class Loan_invite
  attr_reader :id, :user_id, :loan_id
  def initialize(loan_invite_as_hash)
    @id = loan_invite_as_hash["id"]
    @user_id = loan_invite_as_hash["user_id"]
    @loan_id = loan_invite_as_hash["loan_id"]
  end
  def print
    puts "Loan_invite"
    puts "id: #{@id}"
    puts "user_id: #{@user_id}"
    puts "loan_id: #{@loan_id}"
  end

end