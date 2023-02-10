require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require_relative 'dao.rb'

enable :sessions

before do
    session[:user_rank] = session[:user_rank] == nil ? "guest" : session[:user_rank]

    if request.path_info != '/sign_in'
        session[:sign_in_error] = ""
    end

    if request.path_info != '/sign_up'
        session[:sign_up_error] = ""
    end

    protected_paths = ["/home"]

    if protected_paths.include?(request.path_info) && session[:user_rank] == "guest"
        redirect('/')
    end
end


get('/') do
    # wipe_users()

    slim(:landing_page)
end


get('/sign_in') do
    slim(:sign_in, locals:{error:session[:sign_in_error]})
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

    session[:sign_in_error] = ""
    session[:user_data] = user
    session[:user_rank] = "user"
    redirect("/home")
end


get('/sign_up') do
    slim(:sign_up, locals:{error:session["sign_up_error"]})
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
    session[:sign_up_error] = ""
    add_user(name, email, password)

    user = get_user(email)
    session[:user_data] = user

    redirect('/home')
end


get('/home') do
    slim(:home, locals:{user:session["user_data"]})
end

get('/sign_out') do
    session.clear
    redirect('/')
end

get('/open_bank_account') do
    slim(:"/bank_account/open_bank_account")
end

get('/open_bank_account/payroll_account') do
    slim(:"/bank_account/payroll_account")
end

post('/open_bank_account/payroll_account') do
    name = params[:name]
    time_now = Time.now.to_i

    add_bank_account(0, time_now, session[:user_data]["id"], name)
end

get('/open_bank_account/savings_account') do
    slim(:"/bank_account/savings_account")
    
end