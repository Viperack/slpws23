get("/home/bank_account/open") do
  slim(:"/home/bank_account/open/index")
end

get("/home/bank_account/open/payroll") do
  slim(:"/home/bank_account/open/payroll")
end

post("/home/bank_account/open/payroll") do
  $db.create_bank_account(session[:user].id, 0, Time.now.to_i, params[:name], 0)

  redirect("/home")
end

get("/home/bank_account/open/savings") do
  interests = $db.get_interest("Savings")

  slim(:"/home/bank_account/open/savings", locals: { interests: interests })
end

post("/home/bank_account/open/savings") do
  transfer_size = string_dollar_to_int_cent(params[:transfer_size])
  time_deposit = params[:time_deposit].split(",")[0].to_i
  rate = params[:time_deposit].split(",")[1].to_i

  if params[:origin_bank_account_id] != "deposit"
    origin_bank_account_id = params[:origin_bank_account_id]

    if $db.update_bank_account(id: origin_bank_account_id, balance: -transfer_size) == -1
      session[:savings_account_create_error] = "Not enough money in bank account"
      redirect("/home/bank_account/open/savings")
      return nil
    end

  else
    origin_bank_account_id = -1
  end

  unlock_date = Time.now.to_i + 3600 * 24 * 365 * time_deposit

  destination_bank_account_id = $db.create_bank_account(session[:user].id, rate, unlock_date, params[:name], 0)

  $db.update_bank_account(id: destination_bank_account_id, balance: transfer_size, locked: 1)

  $db.create_transaction_log(origin_bank_account_id, destination_bank_account_id, transfer_size, Time.now.to_i)

  redirect("/home")
end

get("/home/bank_account/:index/close") do
  slim(:"home/bank_account/close", locals: { bank_accounts: session[:bank_accounts], index: params[:index].to_i })
end

post("/home/bank_account/close") do
  balance_size = $db.get_bank_accounts(attribute: "id", value: params["origin_bank_account_id"]).first.balance

  $db.delete_bank_account(params["origin_bank_account_id"])

  $db.update_bank_account(id: params["destination_bank_account_id"],balance: balance_size)

  $db.create_transaction_log(params["origin_bank_account_id"], params["destination_bank_account_id"], balance_size, Time.now.to_i)

  redirect("/home")
end

get("/home/deposit") do
  slim(:"home/deposit", locals: { bank_accounts: session[:bank_accounts] })
end

post("/home/deposit") do
  deposit_size = string_dollar_to_int_cent(params["deposit_size"])

  $db.update_bank_account(id: params["destination_bank_account_id"], balance: deposit_size)

  $db.create_transaction_log(-1, params["destination_bank_account_id"], deposit_size, Time.now.to_i)

  redirect("/home")
end

get("/home/transfer") do
  slim(:"home/transfer")
end

post("/home/transfer") do
  destination_iban = params["destination_iban"].gsub(/\s+/, "").gsub("-", "")
  transfer_size = string_dollar_to_int_cent(params["transfer_size"])

  destination_bank_account_id = params["destination_bank_account_id"] == "IBAN" ? $db.get_bank_accounts(iban: destination_iban).first.id : params["destination_bank_account_id"]

  if destination_bank_account_id == nil
    session[:transfer_error] = "No bank account in Santeo Bank has that IBAN"
    redirect("/home/transfer")
    return nil
  end

  if $db.get_bank_accounts(attribute: "id", value: destination_bank_account_id).first.locked == 1
    session[:transfer_error] = "Can't send money to a locked savings account"
    redirect("/home/transfer")
    return nil
  end

  if $db.update_bank_account(id: params["origin_bank_account_id"], balance: -transfer_size) == -1
    session[:transfer_error] = "Not enough money in bank account"
    redirect("/home/transfer")
    return nil
  end

  $db.update_bank_account(id: destination_bank_account_id, balance: transfer_size)

  $db.create_transaction_log(params["origin_bank_account_id"], destination_bank_account_id, transfer_size, Time.now.to_i)

  redirect("/home")
end

get("/home/bank_account/:index/add_user") do
  bank_account_id = session[:bank_accounts][params[:index].to_i]["id"]

  slim(:"home/bank_account/add_user", locals: { bank_account_id: bank_account_id, index: params[:index] })
end

post("/home/bank_account/:index/add_user") do
  user = $db.get_users(email: params[:add_user_email]).first

  if user == nil
    session[:add_user_to_account_error] = "There are no users with that email adress in Santeo Bank"
    redirect("/home/bank_account/#{params[:index]}/add_user")
    return nil
  end

  $db.create_user_bank_account_rel(user.id, params[:bank_account_id])

  redirect("/home")
end

get("/home/loan/take") do
  rate = $db.get_interest("Loan").first.rate

  slim(:"/home/loan/take", locals: { rate: rate })
end

post("/home/loan/take") do
  loan_size = string_dollar_to_int_cent(params["loan_size"])

  loan_id = $db.create_loan(session[:user]["id"], loan_size)

  $db.update_bank_account(id: params["destination_bank_account_id"], balance: loan_size)

  $db.create_transaction_log(-2, session[:user]["id"], loan_size, Time.now.to_i)

  redirect("/home")
end

get("/home/loan/:index/pay") do
  slim(:"/home/loan/pay", locals: { index: params[:index] })
end

post("/home/loan/:index/pay") do
  loan_payment_size = string_dollar_to_int_cent(params[:loan_payment_size])

=begin
    puts "DEBUG:"
    p loan_payment_size 
    p $db.get_loan_amount_remaining(session[:loans][index]["id"])
=end

  if loan_payment_size > get_loan_rest(session[:loans][params[:index].to_i].id)
    session[:pay_loan_error] = "Can't more than the size of the loan"
    redirect("/home/loan/#{params[:index].to_i}/pay")
    return nil
  end

  origin_bank_account = $db.get_bank_accounts(attribute: "id", value: params[:origin_bank_account_id]).first

  if $db.update_bank_account(id: origin_bank_account, balance: -loan_payment_size) == -1
    session[:pay_loan_error] = "Not enough money in bank account"
    redirect("/home/loan/#{params[:index].to_i}/pay")
    return nil
  end
  $db.update_loan(session[:loans][index]["id"], loan_payment_size)

  $db.create_transaction_log(session[:user].id, -2, loan_payment_size, Time.now.to_i)

  redirect("/home")
end

get("/home/loan/:index/add_user") do
  loan_id = session[:loans][params[:index].to_i]["id"]

  slim(:"/home/loan/add_user", locals: { loan_id: loan_id, index: params[:index] })
end

post("/home/loan/:index/add_user") do
  user = $db.get_users(email: params[:add_user_email]).first

  if user == nil
    session[:add_user_to_loan_error] = "There are no users with that email adress in Santeo Bank"
    redirect("/home/loan/#{params[:index]}/add_user")
    return nil
  end

  $db.create_user_loan_rel(user.id, params[:loan_id])

  redirect("/home")
end 
