require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

$db = SQLite3::Database.new("db/db.db")
$db.results_as_hash = true

def add_user(name, email, password)
    password_digest = BCrypt:Password.create(password)

    $db.execute("INSERT INTO User (name, email, password) VALUES (?, ?, ?)", name, email, password_digest)
end

def check_login(email, password)
    password_digest = BCrypt:Password.create(password)

    response = $db.execute("SELECT * FROM User WHERE email = ? AND password = ?", email, password_digest)

    return response.length > 0 ? response[0] : nil
end