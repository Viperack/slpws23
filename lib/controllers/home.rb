get("/home") do
  session[:bank_accounts] = $db.get_bank_accounts(attribute: "user_id", value: session[:user].id)
  session[:loans] = $db.get_loans(attribute: "user_id", value: session[:user].id)
  loan_invite_ids = $db.get_loan_invites(session[:user].id)
  loan_invites = loan_invite_ids.each { |loan_invite_id | get_loans(id: loan_invite_id) }

  slim(:"home/index", locals: {bank_accounts: session[:bank_accounts], loans: session[:loans], loan_invites: loan_invites})
end