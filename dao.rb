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

# User

def add_user(name, email, password)
    password_digest = BCrypt::Password.create(password)

    $db.execute("INSERT INTO User (name, email, password) VALUES (?, ?, ?)", name, email, password_digest)
end

def get_user(email)
    $db.execute("SELECT * FROM User WHERE email = ?", email).first
end

# Bank account

def get_bank_account(bank_account_id)
    return $db.execute("SELECT * FROM Bank_account WHERE id = ?", bank_account_id).first
end

def get_all_bank_accounts()
    return $db.execute("SELECT * FROM Bank_account")
end

def get_user_bank_accounts(user_id)
    $db.execute("SELECT * FROM User_bank_account_rel INNER JOIN Bank_account ON User_bank_account_rel.bank_account_id = Bank_account.id WHERE user_id = ?", session[:user_data]["id"])
end

# Miscellaneous

def add_bank_account(interest, unlock_date, name, locked)
    bban = Random.rand(100000000)
    bban_string = int_to_string(bban, 8)

    while $db.execute("SELECT * FROM Bank_account WHERE iban = ?", bban_string).length != 0
        bban = Random.rand(100000000)
        bban_string = int_to_string(bban)
    end

    iban = "GB" + bban.digits.sum.to_s + bban_string

    $db.execute("INSERT INTO Bank_account (balance, name, interest, unlock_date, iban, locked) VALUES (?, ?, ?, ?, ?, ?)", 0, name, interest, unlock_date, iban, locked)

    bank_account_id = $db.execute('SELECT last_insert_rowid()')[0]['last_insert_rowid()']

    $db.execute("INSERT INTO User_bank_account_rel (user_id, bank_account_id) VALUES (?, ?)", session[:user_data]["id"], bank_account_id)
end

def change_balance(bank_account_id, size)
    if get_bank_account(bank_account_id)["balance"] + size < 0
        return nil
    end

    $db.execute("UPDATE Bank_account SET balance = balance + ? WHERE id = ?", size, bank_account_id)
end

def close_bank_account(bank_account_id)
    $db.execute("DELETE FROM Bank_account WHERE id = ?", bank_account_id)
    $db.execute("DELETE FROM User_bank_account_rel WHERE bank_account_id = ?", bank_account_id)
end

def get_id_from_iban(iban)
    response = $db.execute("SELECT id FROM Bank_account WHERE iban = ?", iban)

    if response.length == 0
        return nil
    end

    return response[0]["id"]
end

def get_interest_rates()
    $db.execute("SELECT * FROM Interest_rate")
end

def change_lock(bank_account_id, locked)
    $db.execute("UPDATE Bank_account SET locked = ? WHERE id = ?", locked, bank_account_id)
end
