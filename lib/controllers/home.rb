get("/home") do
    session[:bank_accounts] = $db.get_bank_accounts(attribute: "user_id", value: session[:user_data]["id"])
    session[:loans] = $db.get_loans(attribute: "user_id", value: session[:user_data]["id"])
    loan_invites = $db.get_loan_invites(session[:user_data]["id"])

    for loan_invite in loan_invites
        get_loans("id")
    end


    
    slim(:"home/index", locals:{bank_accounts: session[:bank_accounts], loans: session[:loans]})
end