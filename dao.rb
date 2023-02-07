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
    
end

def wipe_users()
    $db.execute("DELETE FROM User")
end