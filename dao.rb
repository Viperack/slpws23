require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

$db = SQLite3::Database.new("db/db.db")
$db.results_as_hash = true

def int_to_string(int, string_length)
    string = int.to_s

    for i in 0...(string_length-string.length)
        string = "0" + string
    end

    return string
end

def add_user(name, email, password)
    password_digest = BCrypt::Password.create(password)

    $db.execute("INSERT INTO User (name, email, password) VALUES (?, ?, ?)", name, email, password_digest)
end

def user_exists?(email)
    response = $db.execute("SELECT * FROM User WHERE email = ? ", email)

    return response[0]
end

def get_user(email)
    response = $db.execute("SELECT * FROM User WHERE email = ?", email)

    user = response.first

    return user
end

def get_user_bank_accounts(user_id)
    user_id = session[:user_data]["id"]

    $db.execute("SELECT * FROM User_bank_account_rel INNER JOIN Bank_account ON User_bank_account_rel.bank_account_id = Bank_account.id WHERE user_id = ?", user_id)
end

# At riskt for SQL Injection, should only be used by developer
def wipe_table(table)
    $db.execute("DELETE FROM #{table}")
end

def add_bank_account(interest, unlock_date, name)
    bban = Random.rand(100000000)
    bban_string = int_to_string(bban, 8)

    while $db.execute("SELECT * FROM Bank_account WHERE iban = ?", bban_string).length != 0
        bban = Random.rand(100000000)
        bban_string = int_to_string(bban)
    end

    digits_sum = bban.digits.sum
    bban_string = "GB" + digits_sum.to_s + bban_string

    $db.execute("INSERT INTO Bank_account (balance, name, interest, unlock_date, iban) VALUES (?, ?, ?, ?, ?)", 0, name, interest, unlock_date, bban_string)

    bank_account_id = $db.execute('SELECT last_insert_rowid()')[0]['last_insert_rowid()']
    user_id = session[:user_data]["id"]

    $db.execute("INSERT INTO User_bank_account_rel (user_id, bank_account_id) VALUES (?, ?)", user_id, bank_account_id)
end

def get_balance(bank_account_id)
    $db.execute("SELECT balance FROM Bank_account WHERE id = ?", bank_account_id)[0]["balance"]
end

def change_balance(bank_account_id, size)
    if get_balance(bank_account_id) + size < 0
        return nil
    end

    $db.execute("UPDATE Bank_account SET balance = balance + ? WHERE id = ?", size, bank_account_id)
end

def close_bank_account(bank_account_id)
    $db.execute("DELETE FROM Bank_account WHERE id = ?", bank_account_id)
    $db.execute("DELETE FROM User_bank_account_rel WHERE bank_account_id = ?", bank_account_id)
end
