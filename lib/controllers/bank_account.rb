get("/home/open_bank_account") do
    slim(:"/home/open_bank_account/index")
end

get("/home/open_bank_account/payroll_account") do
    slim(:"/home/open_bank_account/payroll_account")
end

post("/home/open_bank_account/payroll_account") do
    name = params[:name]
    time_now = Time.now.to_i

    $db.add_bank_account(session[:user_data]["id"], 0, time_now, name, 0)

    redirect("/home")
end

get("/home/open_bank_account/savings_account") do
    interest_rates = $db.get_interest_rates()

    slim(:"home/open_bank_account/savings_account", locals:{interest_rates:interest_rates})
end

post("/home/open_bank_account/savings_account") do
    name = params[:name]
    time_deposit = params[:time_deposit].split(",")[0].to_i
    interest_rate = params[:time_deposit].split(",")[1].to_i

    unlock_date = Time.now.to_i + 3600 * 24 * 365 * time_deposit

    $db.add_bank_account(session[:user_data]["id"], interest_rate, unlock_date, name, 1)

    redirect("/home")
end

get("/home/close_bank_account/:index") do
    index = params[:index].to_i

    slim(:"home/close_bank_account", locals:{bank_accounts:session[:bank_accounts], index:index})
end

post("/home/close_bank_account") do

    destination_bank_account_id = params["destination_bank_account_id"]
    origin_bank_account_id = params["origin_bank_account_id"]

    puts "origin: #{origin_bank_account_id}, destination: #{destination_bank_account_id}"

    balance_size = $db.get_bank_accounts(attribute: "id", value: origin_bank_account_id).first["balance"]

    $db.update_balance(origin_bank_account_id, -balance_size)
    $db.update_balance(destination_bank_account_id, balance_size)

    $db.close_bank_account(origin_bank_account_id)

    $db.add_transaction_log(origin_bank_account_id, destination_bank_account_id, balance_size, Time.now.to_i)
    
    redirect("/home")
end

get("/home/deposit") do
    slim(:"home/deposit", locals:{bank_accounts:session[:bank_accounts]})
end

post("/home/deposit") do
    destination_bank_account_id = params["destination_bank_account_id"]
    deposit_size = (params["deposit_size"].to_f * 100).to_i

    $db.update_balance(destination_bank_account_id, deposit_size)

    $db.add_transaction_log(-1, destination_bank_account_id, deposit_size, Time.now.to_i)


    redirect("/home")
end

get("/home/transfer") do
    slim(:"home/transfer", locals:{bank_accounts:session[:bank_accounts]})
end

post("/home/transfer") do
    destination_iban = params["destination_iban"].gsub(/\s+/, "").gsub("-", "")
    transfer_size = (params["transfer_size"].to_f * 100).to_i
    
    if destination_iban == ""
        destination_bank_account_id = params["destination_bank_account_id"]
    else
        destination_bank_account_id = $db.get_id_from_iban(destination_iban)
    end

    if destination_bank_account_id == nil
        session[:transfer_error] = "No bank account in Santeo Bank has that IBAN"
        redirect("/home/transfer")

    end

    if $db.get_bank_accounts(attribute: "id", value: destination_bank_account_id).first["locked"] == 1
        session[:transfer_error] = "Can't send money to a locked savings account"
        redirect("/home/transfer")
    end

    if $db.update_balance(params["origin_bank_account_id"], -transfer_size) == nil
        session[:transfer_error] = "Not enough money in bank account"
        redirect("/home/transfer")
    end
    $db.update_balance(destination_bank_account_id, transfer_size)

    $db.add_transaction_log(params["origin_bank_account_id"], destination_bank_account_id, transfer_size, Time.now.to_i)

    session[:transfer_error] = ""
    redirect("/home")
end

get("/home/add_user_to_account/:index") do
    bank_account_id = session[:bank_accounts][params[:index].to_i]

    slim(:"home/add_user_to_account", locals:{bank_account_id:bank_account_id})
end

post("/home/add_user_to_account/:index") do
    bank_account_id = params[:bank_account_id]
    email = params[:add_user_email]

    user_id = $db.get_user(email)["id"]

    if user_id == nil
        session[:add_user_to_account_error] = "There are no users with that email adress in Santeo Bank"
        redirect("/home")
    end

    session[:add_user_to_account_error] = ""
    redirect("/home")
end

get("/home/take_loan") do
    slim(:"/home/take_loan", locals:{bank_accounts: session[:bank_accounts]})
end

post("/home/take_loan") do
    loan_size = (params["loan_size"].to_f * 100).to_i

    $db.add_loan(session[:user_data]["id"], loan_size)

    $db.update_balance(params["destination_bank_account_id"], loan_size)

    $db.add_transaction_log(-2, session[:user_data]["id"], loan_size, Time.now.to_i)

    redirect("/home")
end
