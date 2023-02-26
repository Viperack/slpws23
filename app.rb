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

    unprotected_paths = ['/', '/sign_in', '/sign_up']

    if !unprotected_paths.include?(request.path_info) && session[:user_rank] == "guest"
        redirect('/')
    end
end

helpers do
    def display_balance(balance)
        (balance / 100.0).round(2)
    end

    def display_iban(iban_string)
        iban_string.insert(4, " ")
        iban_string.insert(9, " ")

        return iban_string
    end
end

get('/') do
    slim(:index)
end


get('/sign_in') do
    slim(:sign_in, locals:{error:session[:sign_in_error]})
end

post('/sign_in') do
    email = params["email"]
    password  = params["password"]

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
    user = session[:user_data]
    user_id = user["id"]

    session[:bank_accounts] = get_user_bank_accounts(user_id)
    bank_accounts = session[:bank_accounts]

    slim(:"home/index", locals:{user:user, bank_accounts:bank_accounts})
end

get('/sign_out') do
    session.clear
    redirect('/')
end

get('/open_bank_account') do
    slim(:"/home/open_bank_account/index")
end

get('/open_bank_account/payroll_account') do
    slim(:"/home/open_bank_account/payroll_account")
end

post('/open_bank_account/payroll_account') do
    name = params[:name]
    time_now = Time.now.to_i

    add_bank_account(0, time_now, name)

    redirect('/home')
end

get('/open_bank_account/savings_account') do
    slim(:"home/open_bank_account/savings_account")
    
end

get('/home/close_bank_account/:index') do
    index = params[:index].to_i
    bank_accounts = session[:bank_accounts]

    slim(:"home/close_bank_account", locals:{bank_accounts:bank_accounts, index:index})
    
end

post('/home/close_bank_account') do
    destination_bank_account_id = params["destination_bank_account"]
    origin_bank_account_id = params["origin_bank_account"]

    puts "origin: #{origin_bank_account_id}, destination: #{destination_bank_account_id}"

    size = get_balance(origin_bank_account_id)

    change_balance(origin_bank_account_id, -size)
    change_balance(destination_bank_account_id, size)

    close_bank_account(origin_bank_account_id)
    
    redirect('/home')
end

get('/home/deposit') do
    bank_accounts = session[:bank_accounts]

    slim(:"home/deposit", locals:{bank_accounts:bank_accounts})
end

post('/home/deposit') do
    destination_bank_account_id = params["destination_bank_account"]
    deposit_size = (params["deposit_size"].to_f * 100).to_i

    change_balance(destination_bank_account_id, deposit_size)

    redirect('/home')
end

get('/home/transfer') do
    slim(:"home/transfer")
end