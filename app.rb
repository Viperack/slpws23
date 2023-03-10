require "sinatra"
require "slim"
require "sqlite3"
require "sinatra/reloader"
require "async"

require_relative "lib/model.rb"
require_relative "lib/controllers/routes.rb"

$db = Database.new("db/db.db")

enable :sessions

Thread.new do
    while true
        bank_accounts = $db.get_bank_accounts()
        time = Time.now.to_i

        for bank_account in bank_accounts
            if bank_account["interest"] == 1 && bank_account["unlock_date"] <= time
                interest = (bank_account["balance"] * (bank_account["interest"] / 10000.0)).ceil(2)
                
                $db.update_balance(bank_account["id"], interest)
                $db.update_lock(bank_account["id"], 0)

                $db.add_transaction_log(-2, bank_account["id"], interest, Time.now.to_i)
            end
        end

        sleep(60)
    end
end

before do
    session[:user_rank] = session[:user_rank] == nil ? "guest" : session[:user_rank]

    if request.path_info != "/sign_in"
        session[:sign_in_error] = ""
    end

    if request.path_info != "/sign_up"
        session[:sign_up_error] = ""
    end

    if request.path_info != "/home/bank_account/open/savings"
        session[:savings_account_create_error] = ""
    end

    if request.path_info != "/home/transfer"
        session[:transfer_error] = ""
    end

    if request.path_info != "/home/bank_account/:index/add_user"
        session[:add_user_to_account_error] = ""
    end

    if request.path_info != "/home/loan/:index/pay"
        session[:pay_loan_error] = ""
    end

    unprotected_paths = ["/", "/sign_in", "/sign_up", "/debug"]

    if !unprotected_paths.include?(request.path_info) && session[:user_rank] == "guest"
        redirect("/")
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
        return Time.at(seconds)
    end

    def string_dollar_to_int_cent(string_dollar)
        (string_dollar.to_f * 100).to_i
    end
end
