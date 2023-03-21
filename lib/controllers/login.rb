get("/") do
  # Restet database
  # $db.wipe_all()

  # For debugging
  redirect("/debug")

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

  user_as_hash = $db.get_users(email: params["email"]).first
  user = User.new(user_as_hash)

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

  redirect("/home")
end

get("/sign_out") do
  session.clear
  redirect("/")
end

get("/debug") do
  email = "theok04@gmail.com"
  password = "1"

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

  user_exists = $db.get_user(email) != nil

  if !user_exists
    session[:sign_in_error] = "No user with that email adress exist"
    redirect("sign_in")
    return nil
  end

  user = $db.get_user(email)

  if BCrypt::Password.new(user["password"]) != password
    session[:sign_in_error] = "Wrong combinations of email and password"
    redirect("sign_in")
    return nil
  end

  session[:user] = user

  redirect("/home")
end