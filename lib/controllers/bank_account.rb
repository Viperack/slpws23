get("/home/bank_account/open") do
    slim(:"/home/bank_account/open/index")
end

get("/home/bank_account/open/payroll") do
    slim(:"/home/bank_account/open/payroll")
end

post("/home/bank_account/open/payroll") do
    username = params[:name]
    time_now = Time.now.to_i

    $db.add_bank_account(session[:user_data]["id"], 0, time_now, username, 0)

    redirect("/home")
end

get("/home/bank_account/open/savings") do
    interest_rates = $db.get_interest_rates("Savings")

    slim(:"/home/bank_account/open/savings", locals:{bank_accounts: session[:bank_accounts], interest_rates:interest_rates})
end

post("/home/bank_account/open/savings") do
    transfer_size = string_dollar_to_int_cent(params[:transfer_size]) 
    time_deposit = params[:time_deposit].split(",")[0].to_i
    interest_rate = params[:time_deposit].split(",")[1].to_i

    puts params[:origin_bank_account_id]

    if params[:origin_bank_account_id] != "deposit"
        origin_bank_account_id = params[:origin_bank_account_id]

        if $db.update_balance(origin_bank_account_id, -transfer_size) == nil
            session[:savings_account_create_error] = "Not enough money in bank account"
            redirect("/home/bank_account/open/savings")
        end
    else
        origin_bank_account_id = -1
    end
    
    unlock_date = Time.now.to_i + 3600 * 24 * 365 * time_deposit

    $db.add_bank_account(session[:user_data]["id"], interest_rate, unlock_date, params[:name], 0)

    destination_bank_account_id = $db.get_last_insert_id()

    puts "ID: #{destination_bank_account_id}"

    $db.update_balance(destination_bank_account_id, transfer_size)

    $db.update_lock(destination_bank_account_id, 1)

    $db.add_transaction_log(origin_bank_account_id, destination_bank_account_id, transfer_size, Time.now.to_i)

    redirect("/home")
end

get("/home/bank_account/:index/close") do
    index = params[:index].to_i

    slim(:"home/bank_account/close", locals:{bank_accounts:session[:bank_accounts], index:index})
end

post("/home/bank_account/close") do

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
    deposit_size = string_dollar_to_int_cent(params["deposit_size"])

    $db.update_balance(destination_bank_account_id, deposit_size)

    $db.add_transaction_log(-1, destination_bank_account_id, deposit_size, Time.now.to_i)


    redirect("/home")
end

get("/home/transfer") do
    slim(:"home/transfer", locals:{bank_accounts:session[:bank_accounts]})
end

post("/home/transfer") do
    destination_iban = params["destination_iban"].gsub(/\s+/, "").gsub("-", "")
    transfer_size = string_dollar_to_int_cent(params["transfer_size"])
    
    destination_bank_account_id = params["destination_bank_account_id"] == "IBAN" ? $db.get_id_from_iban(destination_iban) : params["destination_bank_account_id"]

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

get("/home/bank_account/:index/add_user") do
    bank_account_id = session[:bank_accounts][params[:index].to_i]

    slim(:"home/bank_account/add_user", locals:{bank_account_id:bank_account_id})
end

post("/home/bank_account/:index/add_user") do
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

get("/home/loan/take") do
    interest = $db.get_interest_rates("Loan").first["interest"]

    slim(:"/home/take_loan", locals:{bank_accounts: session[:bank_accounts], interest: interest})
end

post("/home/take") do
    loan_size = string_dollar_to_int_cent(params["loan_size"])

    $db.add_loan(session[:user_data]["id"], loan_size)

    $db.update_balance(params["destination_bank_account_id"], loan_size)

    $db.add_transaction_log(-2, session[:user_data]["id"], loan_size, Time.now.to_i)

    redirect("/home")
end

=begin
get("/home/:index/pay") do
    slim(:"/home/take_loan", locals:{bank_accounts: session[:bank_accounts]})
end 

post("/home/:index/pay") do
    slim(:"/home/take_loan", locals:{bank_accounts: session[:bank_accounts]})
end 
=end
