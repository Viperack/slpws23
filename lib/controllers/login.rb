get("/") do
    slim(:index)
end


get("/sign_in") do
    slim(:sign_in, locals:{error:session[:sign_in_error]})
end

post("/sign_in") do
    email = params["email"]
    password  = params["password"]

    if email == ""
        session[:sign_in_error] = "Email must be entered to sign in"
        redirect("/sign_in")
    end

    if password == ""
        session[:sign_in_error] = "Password must be entered to sign in"
        redirect("/sign_in")
    end

    user_exists = $db.get_user(email) != nil

    if !user_exists
        session[:sign_in_error] = "No user with that email adress exist"
        redirect("sign_in")
    end

    user = $db.get_user(email)

    if BCrypt::Password.new(user["password"]) != password
        session[:sign_in_error] = "Wrong combinations of email and password"
        redirect("sign_in")
    end

    session[:sign_in_error] = ""

    session[:user_data] = user
    session[:user_rank] = "user"

    session[:bank_accounts] = $db.get_bank_accounts(attribute: "user_id", value: session[:user_data]["id"])
    session[:loans] = $db.get_loans(attribute: "user_id", value: session[:user_data]["id"])

    puts session[:user_data]["id"]
    puts session[:loans]

    p $db.get_bank_accounts(attribute: "id", value: session[:user_data]["id"])

    redirect("/home")
end

get("/sign_out") do
    session.clear
    redirect("/")
end