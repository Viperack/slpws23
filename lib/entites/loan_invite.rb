class Loan_invite
  def initialize(id, user_id, loan_id)
    @id = id
    @user_id = user_id
    @loan_id = loan_id
  end

  def create_from_hash(**loan_invite)
    @id = loan_invite["id"]
    @user_id = loan_invite["user_id"]
    @loan_id = loan_invite["loan_id"]
  end
end