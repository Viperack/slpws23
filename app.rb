require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require_relative 'dao.rb'

enable :sessions

before do
    protected_paths = ["/home"]

    if protected_paths.include?(request.path_info) && session[:user_rank] == "guest"
        redirect('/')
    end
end


get('/') do
    session[:user_error] = "" # FIX, MASSIVE BUG!!!
    session[:user_rank] = "guest"
    balance = 0
    name = "Name"
    # wipe_users()

    slim(:landing_page, locals:{balance:balance, name:name})
end


get('/sign_in') do
    slim(:sign_in, locals:{error:session["user_error"]})
end

post('/sign_in') do
    email = params["email"]
    password  = params["password"]

    # puts "DEBUG #{email} #{password}"

    if email == ""
        session["user_error"] = "Email must be entered to sign in"
        redirect("/sign_in")
    end

    if password == ""
        session["user_error"] = "Password must be entered to sign in"
        redirect("/sign_in")
    end

    user_exists = user_exists?(email)

    if !user_exists
        session["user_error"] = "No user with that email adress exist"
        redirect("sign_in")
    end

    user = get_user(email)

    if BCrypt::Password.new(user["password"]) != password
        session["user_error"] = "Wrong combinations of email and password"
        redirect("sign_in")
    end

    session["user_error"] = ""
    session["user_data"] = user
    session[:user_rank] = "user"
    redirect("/home")
end


get('/sign_up') do
    slim(:sign_up, locals:{error:session["user_error"]})
end

post('/sign_up') do
    name = params["name"]
    email = params["email"]
    password  = params["password"]
    password_confirm = params["password_confirm"]

    if name == ""
        session["user_error"] = "Name must be entered to sign up"
        redirect("/sign_up")
    end

    if email == ""
        session["user_error"] = "Email must be entered to sign up"
        redirect("/sign_up")
    end

    if password == ""
        session["user_error"] = "Password must be entered to sign up"
        redirect("/sign_up")
    end

    if password != password_confirm
        session["user_error"] = "Passwords don't match"
        redirect("/sign_up")
    end

    # Everything has been checked
    session["user_error"] = ""
    add_user(name, email, password)
    redirect('/home')
end


get('/home') do
    slim(:home, locals:{user:session["user_data"]})
end