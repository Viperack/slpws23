# Shows the transaction logs
get("/transaction") do
  if session[:user].permission_level != 1
    redirect("/access_denied")
  end

  transactions_logs = $db.get_transactions_logs

  slim(:transaction, locals:{transactions_logs: transactions_logs})
end

# Shows the interests
get("/interest") do
  if session[:user].permission_level != 1
    redirect("/access_denied")
  end

  interests = $db.get_interest

  slim(:"interest/index", locals:{interests: interests})

end

# Takes in the information for the update of an interest
get("/interest/:id/update") do
  if session[:user].permission_level != 1
    redirect("/access_denied")
  end

  interests = $db.get_interest
  interest = interests.select { |interest| interest.id == params[:id].to_i}.first

  slim(:"interest/update", locals:{interest: interest})
end

# Performes error handling and creates a user account
#
# @param [String] :id The id of the interest
# @param [String] :rate The new interest rate
# @param [String] :time_deposit The new time_deposit
post("/interest/:id/update") do
  if session[:user].permission_level != 1
    redirect("/access_denied")
  end

  $db.update_interest(id: params[:id].to_i, rate: string_dollar_to_int_cent(params[:rate]), time_deposit: params[:time_deposit].to_i)

  redirect("/interest")
end
