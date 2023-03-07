get("/home") do
    session[:bank_accounts] = $db.get_bank_accounts(attribute: "user_id", value: session[:user_data]["id"])
    session[:loans] = $db.get_loans(attribute: "user_id", value: session[:user_data]["id"])
    
    slim(:"home/index", locals:{user: session[:user_data], bank_accounts: session[:bank_accounts], loans: session[:loans]})
end