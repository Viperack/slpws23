get("/home") do
    slim(:"home/index", locals:{user: session[:user_data], bank_accounts: session[:bank_accounts], loans: session[:loans]})
end