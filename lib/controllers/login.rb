get("/") do
  # Reset database
  # $db.reset_database

  # For debugging
  # redirect("/debug")

  slim(:index)
end

get("/sign_in") do
  slim(:sign_in)
end

post("/sign_in") do

  if params["email"] == ""
    session[:sign_in_error] = "Email must be entered to sign in"
    redirect("/sign_in")
    return nil
  end

  if params["password"] == ""
    session[:sign_in_error] = "Password must be entered to sign in"
    redirect("/sign_in")
    return nil
  end

  user = $db.get_users(email: params["email"]).first

  if !user
    session[:sign_in_error] = "No user with that email adress exist"
    redirect("sign_in")
    return nil
  end

  if BCrypt::Password.new(user.password_digest) != params["password"]
    session[:sign_in_error] = "Wrong combinations of email and password"
    redirect("sign_in")
    return nil
  end

  session[:user] = user

  if user.permission_level == 0
    redirect("/home")
  elsif user.permission_level == 1
    redirect("/transaction")
  end
end

get("/sign_out") do
  session.clear
  redirect("/")
end

get("/debug") do
  email = "theok04@gmail.com"
  password = 1

  if email == ""
    session[:sign_in_error] = "Email must be entered to sign in"
    redirect("/sign_in")
    return nil
  end

  if password == ""
    session[:sign_in_error] = "Password must be entered to sign in"
    redirect("/sign_in")
    return nil
  end

  user = $db.get_users(email: email).first

  if !user
    session[:sign_in_error] = "No user with that email adress exist"
    redirect("sign_in")
    return nil
  end

  if BCrypt::Password.new(user.password_digest) != password
    session[:sign_in_error] = "Wrong combinations of email and password"
    redirect("sign_in")
    return nil
  end

  session[:user] = user

  if user.permission_level == 0
    redirect("/home")
  elsif user.permission_level == 1
    redirect("/transaction")
  end

end