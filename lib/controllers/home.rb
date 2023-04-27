# Shows the user the home pages which contains the users bank accounts, lonas and loan invites
get("/home") do
  session[:bank_accounts] = $db.get_bank_accounts(user_id: session[:user].id)
  session[:loans] = $db.get_loans(user_id: session[:user].id)

  loan_invites = $db.get_loan_invites(session[:user].id)
  loan_invites_as_loans = []
  loan_invites.each { |loan_invite | loan_invites_as_loans << $db.get_loans(id: loan_invite.loan_id).first }

  loan_invites_owners = []
  loan_invites_as_loans.each do |loan_invites_as_loan |
    user_ids = $db.get_user_id_from_loan_rel(loan_invites_as_loan.id)
    user_ids.each {|user_id| loan_invites_owners << $db.get_users(id: user_id["user_id"])}

  end

  slim(:"home/index", locals: {bank_accounts: session[:bank_accounts], loans: session[:loans], loan_invites_as_loans: loan_invites_as_loans, loan_invites_owners: loan_invites_owners, loan_invites: loan_invites})
end