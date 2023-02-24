require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

$db = SQLite3::Database.new("db/db.db")
$db.results_as_hash = true

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
    $db.execute("INSERT INTO Bank_account (balance, interest, unlock_date, name) VALUES (?, ?, ?, ?)", 0, interest, unlock_date, name)

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
    $db.execute("DELETE Bank_account WHERE id = ?", bank_account_id)
end