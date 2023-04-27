# Takes information from the user to create a bank accoount and can display error messages
get("/sign_up") do
  slim(:sign_up)
end

# Performes error handling and creates a user account
#
# @param [String] "name" The name of the user
# @param [String] "email" The email of the user
# @param [String] "password" The password of the user
# @param [String] "password_confirm" The password that is used to check if the user wrote the right password
post("/sign_up") do
  if params["name"] == ""
    session[:sign_up_error] = "Name must be entered to sign up"
    redirect("/sign_up")
    return nil
  end

  if params["email"] == ""
    session[:sign_up_error] = "Email must be entered to sign up"
    redirect("/sign_up")
    return nil
  end

  if params["password"] == ""
    session[:sign_up_error] = "Password must be entered to sign up"
    redirect("/sign_up")
    return nil
  end

  if params["password"] != params["password_confirm"]
    session[:sign_up_error] = "Passwords don't match"
    redirect("/sign_up")
    return nil
  end

  # Everything has been checked
  $db.create_user(params["name"], params["email"], params["password"], 0)

  session[:user] = $db.get_users(email: params["email"]).first

  if session[:user].permission_level == 0
    redirect("/home")
  elsif session[:user].permission_level == 1
    redirect("/transaction")
  end
end