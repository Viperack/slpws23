# Shows the different kinds of bank accounts
get("/home/bank_account/open") do
  slim(:"/home/bank_account/open/index")
end

# Takes in information to open a payroll account
get("/home/bank_account/open/payroll") do
  slim(:"/home/bank_account/open/payroll")
end

# Opens a payroll account
#
# @param [String] :name The name of the payroll account
post("/home/bank_account/open/payroll") do
  $db.create_bank_account(session[:user].id, 0, Time.now.to_i, params[:name], 0)

  redirect("/home")
end

# Takes in information to open a savings account
get("/home/bank_account/open/savings") do
  interests = $db.get_interest(type: "Savings")

  slim(:"/home/bank_account/open/savings", locals: { interests: interests })
end

# Opens a savings account
#
# @param [String] :transfer_size The size of the money put into the savings account
# @param [String] :time_deposit For how long the account should be locked
# @param [String] :origin_bank_account_id The id of the bank account where the money comes from. -1 = deposit
# @param [String] :name The name of savings account
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

# Takes in information to close a bank account
get("/home/bank_account/:id/close") do
  closing_bank_account_id = params[:id].to_i

  is_owner = false
  session[:bank_accounts].each { |bank_account| is_owner = true if bank_account.id == closing_bank_account_id}

  if !is_owner
    redirect("/access_denied")
  end

  closing_bank_account = session[:bank_accounts].select {|bank_account| bank_account.id == closing_bank_account_id}.first

  slim(:"home/bank_account/close", locals: { closing_bank_account: closing_bank_account, bank_accounts: session[:bank_accounts]})
end

# Closes a bank account
#
# @param [String] :id The id of the closing bank account
# @param [String] "origin_bank_account_id" The id of the account where the money comes from
# @param [String] "destination_bank_account_id" The id of the bank account where the money should be sent
post("/home/bank_account/:id/close") do
  closing_bank_account_id = params[:id].to_i

  is_owner = false
  session[:bank_accounts].each { |bank_account| is_owner = true if bank_account.id == closing_bank_account_id}

  if !is_owner
    redirect("/access_denied")
  end

  balance_size = $db.get_bank_accounts(id: params["origin_bank_account_id"]).first.balance

  $db.delete_bank_account(params["origin_bank_account_id"])

  $db.update_bank_account(id: params["destination_bank_account_id"], balance: balance_size)

  $db.create_transaction_log(params["origin_bank_account_id"], params["destination_bank_account_id"], balance_size, Time.now.to_i)

  redirect("/home")
end

# Takes in information to make a deposit
get("/home/deposit") do
  slim(:"home/deposit", locals: { bank_accounts: session[:bank_accounts] })
end

# Makes a deposit
#
# @param [String] "deposit_size" The amount of money deposited
# @param [String] "destination_bank_account_id" The id of the bank account where the money is sent
post("/home/deposit") do
  deposit_size = string_dollar_to_int_cent(params["deposit_size"])

  $db.update_bank_account(id: params["destination_bank_account_id"].to_i, balance: deposit_size)

  $db.create_transaction_log(-1, params["destination_bank_account_id"].to_i, deposit_size, Time.now.to_i)

  redirect("/home")
end

# Takes in information to make a transfer
get("/home/transfer") do
  slim(:"home/transfer")
end

# Makes a transfer
#
# @param [String] "destination_iban" The iban of the bank account where the money is sent
# @param [String] "transfer_size" The size of the transfer
# @param [String] "destination_bank_account_id" The id of the bank account where the money is sent
# @param [String] "origin_bank_account_id" The id of the bank account where the money is from
post("/home/transfer") do
  destination_iban = params["destination_iban"].gsub(/\s+/, "").gsub("-", "")
  transfer_size = string_dollar_to_int_cent(params["transfer_size"])

  destination_bank_account_id = params["destination_bank_account_id"] == "IBAN" ? $db.get_bank_accounts(iban: destination_iban).first.id : params["destination_bank_account_id"]

  if destination_bank_account_id == nil
    session[:transfer_error] = "No bank account in Santeo Bank has that IBAN"
    redirect("/home/transfer")
    return nil
  end

  if $db.get_bank_accounts(id: destination_bank_account_id).first.locked == 1
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

# Takes in information to add a user to a bank account
get("/home/bank_account/:id/add_user") do
  bank_account_id = params[:id].to_i

  is_owner = false
  session[:bank_accounts].each { |bank_account| is_owner = true if bank_account.id == bank_account_id}

  if !is_owner
    redirect("/access_denied")
  end

  slim(:"home/bank_account/add_user", locals: { bank_account_id: params[:id].to_i })
end

# Adds a user to a bank account
#
# @param [String] :id The id of the bank account
# @param [String] :add_user_email The email of the user that is added
post("/home/bank_account/:id/add_user") do
  bank_account_id = params[:id].to_i

  is_owner = false
  session[:bank_accounts].each { |bank_account| is_owner = true if bank_account.id == bank_account_id}

  if !is_owner
    redirect("/access_denied")
  end

  added_user = $db.get_users(email: params[:add_user_email]).first

  if added_user == nil
    session[:add_user_to_account_error] = "There are no users with that email address in Santeo Bank"
    redirect("/home/bank_account/#{bank_account_id}/add_user")
    return nil
  end

  user_is_owner = false
  $db.get_bank_accounts(user_id: added_user.id).each { |bank_account|
    if bank_account.id == bank_account_id
      user_is_owner = true
      break
    end
  }

  $db.create_user_bank_account_rel(added_user.id, bank_account_id) if !user_is_owner

  redirect("/home")
end

# Takes in information to make a loan
get("/home/loan/take") do
  rate = $db.get_interest(type: "Loan").first.rate

  slim(:"/home/loan/take", locals: { rate: rate })
end

# Takes a loan
#
# @param [String] "loan_size" The size of the loan
# @param [String] "destination_bank_account_id" The id of the bank account where the money is sent
post("/home/loan/take") do
  loan_size = string_dollar_to_int_cent(params["loan_size"])

  $db.create_loan(session[:user].id, loan_size)

  $db.update_bank_account(id: params["destination_bank_account_id"], balance: loan_size)

  $db.create_transaction_log(-2, session[:user].id, loan_size, Time.now.to_i)

  redirect("/home")
end

# Takes in information to loan payment
get("/home/loan/:id/pay") do
  loan_id = params[:id].to_i

  is_owner = false
  session[:loans].each { |loan| is_owner = true if loan.id == loan_id}

  if !is_owner
    redirect("/access_denied")
  end

  slim(:"/home/loan/pay", locals: { loan_id: params[:id].to_i })
end

# Makes payment on a loan
#
# @param [String] :loan_payment_size The size of the payment
# @param [String] :id The id of the loan
# @param [String] :origin_bank_account_id The id of the bank account where the money is from
post("/home/loan/:id/pay") do
  loan_payment_size = string_dollar_to_int_cent(params[:loan_payment_size])
  loan_id = params[:id].to_i

  is_owner = false
  session[:loans].each { |loan| is_owner = true if loan.id == loan_id}

  if !is_owner
    redirect("/access_denied")
  end

  if loan_payment_size > get_loan_rest(loan_id)
    session[:pay_loan_error] = "Can't pay more than the size of the loan"
    redirect("/home/loan/#{loan_id}/pay")
    return nil
  end

  origin_bank_account_id = $db.get_bank_accounts(id: params[:origin_bank_account_id]).first.id

  if $db.update_bank_account(id: origin_bank_account_id, balance: -loan_payment_size) == -1
    session[:pay_loan_error] = "Not enough money in bank account"
    redirect("/home/loan/#{loan_id}/pay")
    return nil
  end
  $db.update_loan(id: loan_id, amount_payed: loan_payment_size)

  $db.create_transaction_log(session[:user].id, -2, loan_payment_size, Time.now.to_i)

  redirect("/home")
end

# Takes in information to invite a user to a loan
get("/home/loan/:id/add_user") do
  loan_id = params[:id].to_i

  is_owner = false
  session[:loans].each { |loan| is_owner = true if loan.id == loan_id}

  if !is_owner
    redirect("/access_denied")
  end

  slim(:"/home/loan/add_user", locals: { loan_id: loan_id })
end

# Invites a user to a loan
#
# @param [String] :id The id of the loan
# @param [String] :add_user_email The email of the user that is added
post("/home/loan/:id/add_user") do
  added_user = $db.get_users(email: params[:add_user_email]).first
  loan_id = params[:id].to_i

  is_owner = false
  session[:loans].each { |loan| is_owner = true if loan.id == loan_id}

  if !is_owner
    redirect("/access_denied")
  end

  if added_user == nil
    session[:add_user_to_loan_error] = "There are no users with that email address in Santeo Bank"
    redirect("/home/loan/#{loan_id}/add_user")
    return nil
  end

  user_is_owner = false
  $db.get_loans(user_id: added_user.id).each { |loan|
    if loan.id == loan_id
      user_is_owner = true
      break
    end
  }
  $db.get_loan_invites(added_user.id).each { |loan_invite|
    if loan_invite.loan_id == loan_id
      user_is_owner = true
      break
    end
  }

  $db.create_loan_invite(added_user.id, loan_id) if !user_is_owner

  redirect("/home")
end

# Shows the user that they do not have access to the resource they were trying to access
get("/access_denied") do
  slim(:access_denied)
end

# Adds the loan that the user was invited to and removes the loan_invite
#
# @param [String] :id The id of the loan_invite
post("/home/loan_invite/:id/accept") do
  loan_id = nil
  loan_invite_id = params[:id].to_i
  loan_invites = $db.get_loan_invites(session[:user].id)
  puts loan_invites
  is_owner = false
  loan_invites.each { |loan_invite|
    puts loan_invite.id
    puts loan_invite_id
    if loan_invite.id == loan_invite_id
      loan_id = loan_invite.loan_id
      is_owner = true
    end
  }

  if !is_owner
    redirect("/access_denied")
    return nil
  end

  $db.create_user_loan_rel(session[:user].id, loan_id)

  $db.delete_loan_invite(id: loan_invite_id)

  redirect("/home")
end

# Removes the loan_invite
#
# @param [String] :id The id of the loan_invite
post("/home/loan_invite/:id/reject") do
  loan_invite_id = params[:id].to_i
  loan_invites = $db.get_loan_invites(session[:user].id)
  is_owner = false
  loan_invites.each { |loan_invite|
    is_owner = loan_invite.id == loan_invite_id
  }

  if !is_owner
    redirect("/access_denied")
    return nil
  end

  $db.delete_loan_invite(id: loan_invite_id)

  redirect("/home")
end
