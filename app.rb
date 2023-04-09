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
    bank_accounts = $db.get_bank_accounts
    loans = $db.get_loans
    time = Time.now.to_i

    bank_accounts.each { |bank_account|
      if bank_account.interest == 1 && bank_account.unlock_date <= time
        interest = (bank_account.balance * (bank_account.interest / 10000.0)).ceil(2)

        $db.update_bank_account(id: bank_account.id, balance: interest, locked: 0)

        $db.create_transaction_log(-2, bank_account.id, interest, Time.now.to_i)
      end
    }

    loans.each { |loan|
      if loan.interest_payment_date <= time
        interest = (loan.size * (loan.interest / 10000.0)).ceil(2)

        $db.update_loan(id: loan.id, size: interest)

        $db.create_transaction_log(-2, loan.id, interest, Time.now.to_i)
      end
    }


    sleep(60)
  end
end

before do
  if request.path_info != "/sign_in"
    session[:sign_in_error] = nil
  end

  if request.path_info != "/sign_up"
    session[:sign_up_error] = nil
  end

  if request.path_info != "/home/bank_account/open/savings"
    session[:savings_account_create_error] = nil
  end

  if request.path_info != "/home/transfer"
    session[:transfer_error] = nil
  end

  if (request.path_info =~ /\/home\/bank_account\/\d+\/add_user/) == nil
    session[:add_user_to_account_error] = nil
  end

  if (request.path_info =~ /\/home\/loan\/\d+\/pay/) == nil
    session[:pay_loan_error] = nil
  end

  unprotected_paths = %w[/ /sign_in /sign_up /debug]

  if !unprotected_paths.include?(request.path_info) && !session[:user]
    redirect("/")
  end
end

helpers do
  def display_dollars(balance)
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
    dollar_cent_array = string_dollar.split(".", 2).map { |element| element.to_i }

    cent = dollar_cent_array[0] * 100 + (dollar_cent_array[1] == nil ? 0 : dollar_cent_array[1])
  end

  def get_loan_rest(loan_id)
    loan = $db.get_loans(id: loan_id).first

    return loan.size - loan.amount_payed
  end

  def display_users_from_array(user_array)
    string = ""

    (0...(user_array.length - 1)).each { |i|
      string += "#{user_array[i].email} (#{user_array[i].name}), "
    }

    return string + "#{user_array[user_array.length-1].email} (#{user_array[user_array.length-1].name})"
  end

end
