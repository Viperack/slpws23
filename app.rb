require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require_relative 'dao.rb'

enable :sessions
session[:user_error] = ""


get('/') do
    balance = 0
    name = "Name"

    slim(:landing_page, locals:{balance:balance, name:name})
end

get('/sign_in') do
    slim(:sign_in)
end

get('/sign_up') do
    slim(:sign_up, locals:{error:session["user_error"]})
end

post('/sign_in') do
    email = params["email"]
    password  = params["password"]

    # puts "DEBUG #{email} #{password}"

    user = check_login(email, password)

    if user != nil
        session["user_error"] = "Wrong combinations of email and password"
        redirect("/home")
    else
        session["user_error"] = ""
        redirect("sign_in")
    end
end

post('/sign_up') do
    name = params["name"]
    email = params["email"]
    password  = params["password"]
    password_confirm = params["passwor_confirm"]

    if password == password_confirm
        add_user(name, email, password)
    else
        session["user_error"] = "Passwords don't match"
        redirect("/sign_up")
    end

end