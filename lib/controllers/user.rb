get("/sign_up") do
    slim(:sign_up, locals:{error:session[:sign_up_error]})
end

post("/sign_up") do
    username = params["name"]
    email = params["email"]
    password  = params["password"]
    password_confirm = params["password_confirm"]

    if username == ""
        session[:sign_up_error] = "Name must be entered to sign up"
        redirect("/sign_up")
        return nil
    end

    if email == ""
        session[:sign_up_error] = "Email must be entered to sign up"
        redirect("/sign_up")
        return nil
    end

    if password == ""
        session[:sign_up_error] = "Password must be entered to sign up"
        redirect("/sign_up")
        return nil
    end

    if password != password_confirm
        session[:sign_up_error] = "Passwords don't match"
        redirect("/sign_up")
        return nil
    end

    # Everything has been checked
    session[:sign_up_error] = ""
    $db.add_user(username, email, password)

    user = $db.get_user(email)

    session[:user_data] = user
    session[:user_rank] = "user"

    redirect("/home")
end