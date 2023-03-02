get("/sign_up") do
    slim(:sign_up, locals:{error:session[:sign_up_error]})
end

post("/sign_up") do
    name = params["name"]
    email = params["email"]
    password  = params["password"]
    password_confirm = params["password_confirm"]

    if name == ""
        session[:sign_up_error] = "Name must be entered to sign up"
        redirect("/sign_up")
    end

    if email == ""
        session[:sign_up_error] = "Email must be entered to sign up"
        redirect("/sign_up")
    end

    if password == ""
        session[:sign_up_error] = "Password must be entered to sign up"
        redirect("/sign_up")
    end

    if password != password_confirm
        session[:sign_up_error] = "Passwords don't match"
        redirect("/sign_up")
    end

    # Everything has been checked
    session[:sign_up_error] = ""
    $db.add_user(name, email, password)

    user = $db.get_user(email)

    session[:user_data] = user
    session[:user_rank] = "user"

    session[:bank_accounts] = $db.get_bank_accounts(attribute: "user_id", value: session[:user_data]["id"])
    session[:loans] = $db.get_loans(attribute: "user_id", value: session[:user_data]["id"])

    redirect("/home")
end