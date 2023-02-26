require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'date'
require 'async'
require_relative 'dao.rb'

enable :sessions

Thread.new do
    while true
        bank_accounts = get_all_bank_accounts()
        time = Time.now.to_i

        for bank_account in bank_accounts
            if bank_account["interest"] == 1 && bank_account["unlock_date"] <= time
                # puts bank_account
                interest = bank_account["balance"] * (bank_account["interest"] / 10000.0)
                # puts interest
                change_balance(bank_account["id"], interest)
                change_lock(bank_account["id"], 0)
            end
        end

        sleep(60)
    end
end

before do
    session[:user_rank] = session[:user_rank] == nil ? "guest" : session[:user_rank]

    if request.path_info != '/sign_in'
        session[:sign_in_error] = ""
    end

    if request.path_info != '/sign_up'
        session[:sign_up_error] = ""
    end

    if request.path_info != '/home/transfer'
        session[:transfer_error] = ""
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

    def epoch_to_date(seconds)
        if seconds < Time.now.to_i
            return nil
        end

        return Time.at(seconds).to_datetime
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
        session[:sign_in_error] = "Email must be entered to sign in"
        redirect("/sign_in")
    end

    if password == ""
        session[:sign_in_error] = "Password must be entered to sign in"
        redirect("/sign_in")
    end

    user_exists = get_user(email) != nil

    if !user_exists
        session[:sign_in_error] = "No user with that email adress exist"
        redirect("sign_in")
    end

    user = get_user(email)

    if BCrypt::Password.new(user["password"]) != password
        session[:sign_in_error] = "Wrong combinations of email and password"
        redirect("sign_in")
    end

    session[:sign_in_error] = ""
    session[:user_data] = user
    session[:user_rank] = "user"

    redirect("/home")
end


get('/sign_up') do
    slim(:sign_up, locals:{error:session[:sign_up_error]})
end

post('/sign_up') do
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
    add_user(name, email, password)

    user = get_user(email)
    session[:user_data] = user
    session[:user_rank] = "user"

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

    add_bank_account(0, time_now, name, 0)

    redirect('/home')
end

get('/open_bank_account/savings_account') do
    interest_rates = get_interest_rates()

    slim(:"home/open_bank_account/savings_account", locals:{interest_rates:interest_rates})
end

post('/open_bank_account/savings_account') do
    name = params[:name]
    time_deposit = params[:time_deposit].split(",")[0].to_i
    interest_rate = params[:time_deposit].split(",")[1].to_i

    unlock_date = Time.now.to_i + 3600 * 24 * 365 * time_deposit

    add_bank_account(interest_rate, unlock_date, name, 1)

    redirect('/home')
end

get('/home/close_bank_account/:index') do
    index = params[:index].to_i

    slim(:"home/close_bank_account", locals:{bank_accounts:session[:bank_accounts], index:index})
end

post('/home/close_bank_account') do

    destination_bank_account_id = params["destination_bank_account_id"]
    origin_bank_account_id = params["origin_bank_account_id"]

    puts "origin: #{origin_bank_account_id}, destination: #{destination_bank_account_id}"

    size = get_bank_account(origin_bank_account_id)["balance"]

    change_balance(origin_bank_account_id, -size)
    change_balance(destination_bank_account_id, size)

    close_bank_account(origin_bank_account_id)
    
    redirect('/home')
end

get('/home/deposit') do
    slim(:"home/deposit", locals:{bank_accounts:session[:bank_accounts]})
end

post('/home/deposit') do
    destination_bank_account_id = params["destination_bank_account_id"]
    deposit_size = (params["deposit_size"].to_f * 100).to_i

    change_balance(destination_bank_account_id, deposit_size)

    redirect('/home')
end

get('/home/transfer') do
    slim(:"home/transfer", locals:{bank_accounts:session[:bank_accounts]})
end

post('/home/transfer') do
    origin_bank_account_id = params["origin_bank_account_id"]
    destination_iban = params["destination_iban"].gsub(/\s+/, "")
    transfer_size = (params["transfer_size"].to_f * 100).to_i

    destination_bank_account_id = get_id_from_iban(destination_iban)

    if destination_bank_account_id == nil
        session[:transfer_error] = "No bank account in Santeo Bank has that IBAN"
        redirect('/home/transfer')

    end

    if get_bank_account(destination_bank_account_id)["locked"] == 1
        session[:transfer_error] = "Can't send money to a locked savings account"
        redirect('/home/transfer')
    end

    if change_balance(origin_bank_account_id, -transfer_size) == nil
        session[:transfer_error] = "Not enough money in bank account"
        redirect('/home/transfer')
    end
    change_balance(destination_bank_account_id, transfer_size)

    session[:transfer_error] = ""
    redirect('/home')
end

get('/home/add_user_to_account/:index') do
    bank_account_id = session[:bank_accounts][params[:index].to_i]

    slim(:"home/add_user_to_account", locals:{bank_account_id:bank_account_id})
end

post('/home/add_user_to_account/:index') do
    bank_account_id = params[:bank_account_id]
    email = params[:add_user_email]

    user_id = get_user(email)["id"]

    if user_id == nil
        session[:add_user_to_account_error] = "There are no users with that email adress in Santeo Bank"
        redirect('/home')
    end

    session[:add_user_to_account_error] = ""
    redirect('/home')
end