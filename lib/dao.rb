require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require "sinatra/reloader"

class Database
    def initialize(path)
        @db = SQLite3::Database.new(path)
        @db.results_as_hash = true
    end

    def int_to_string(int, string_length)
        string = int.to_s

        for i in 0...(string_length-string.length)
            string = "0" + string
        end

        return string
    end

    def add_user(name, email, password)
        password_digest = BCrypt::Password.create(password)

        @db.execute("INSERT INTO User (name, email, password) VALUES (?, ?, ?)", name, email, password_digest)
    end

    def get_user(email)
        @db.execute("SELECT * FROM User WHERE email = ?", email).first
    end

    # Retrievs bank accounts from the database, with or without filtering attributes.
    #
    # @param where [String] the attributes that banks accounts need to have a matching value on to be retrieved, `"id"`, `"user_id"` or `"iban"`.
    # @param where [String] the value of the attribute that banks accounts need to match to be retrieved.
    # @return [Array<Hash>] array of the retrieved bank accounts.
    def get_bank_accounts(**arguments)
        if arguments[:attribute] == "id"
            return @db.execute("SELECT * FROM Bank_account WHERE id = ?", arguments[:value])

        elsif arguments[:attribute] == "iban"
            return @db.execute("SELECT * FROM Bank_account WHERE iban = ?", arguments[:value])

        elsif arguments[:attribute] == "user_id"
            return @db.execute("SELECT * FROM User_bank_account_rel INNER JOIN Bank_account ON User_bank_account_rel.bank_account_id = Bank_account.id WHERE user_id = ?", arguments[:value])
        end

        return @db.execute("SELECT * FROM Bank_account")
    end

    def get_id_from_iban(iban)
        response = @db.execute("SELECT id FROM Bank_account WHERE iban = ?", iban)

        if response.length == 0
            return nil
        end

        return response[0]["id"]
    end

    def add_bank_account(user_id, interest, unlock_date, name, locked)
        bban = Random.rand(100000000)
        bban_string = int_to_string(bban, 8)

        while @db.execute("SELECT * FROM Bank_account WHERE iban = ?", bban_string).length != 0
            bban = Random.rand(100000000)
            bban_string = int_to_string(bban)
        end

        iban = "GB" + bban.digits.sum.to_s + bban_string

        @db.execute("INSERT INTO Bank_account (balance, name, interest, unlock_date, iban, locked) VALUES (?, ?, ?, ?, ?, ?)", 0, name, interest, unlock_date, iban, locked)

        bank_account_id = @db.execute("SELECT last_insert_rowid()").first["last_insert_rowid()"]

        @db.execute("INSERT INTO User_bank_account_rel (user_id, bank_account_id) VALUES (?, ?)", user_id, bank_account_id)
    end

    def update_balance(bank_account_id, size)
        puts "BALANCE:"
        p get_bank_accounts(attribute: "id", value: bank_account_id).first["balance"]
        puts "SIZE:"
        p size


        if get_bank_accounts(attribute: "id", value: bank_account_id).first["balance"] + size < 0
            return nil
        end

        @db.execute("UPDATE Bank_account SET balance = balance + ? WHERE id = ?", size, bank_account_id)
    end

    def close_bank_account(bank_account_id)
        @db.execute("DELETE FROM Bank_account WHERE id = ?", bank_account_id)
        @db.execute("DELETE FROM User_bank_account_rel WHERE bank_account_id = ?", bank_account_id)
    end

    def get_interest_rates()
        @db.execute("SELECT * FROM Interest_rate")
    end

    def update_lock(bank_account_id, locked)
        @db.execute("UPDATE Bank_account SET locked = ? WHERE id = ?", locked, bank_account_id)
    end

    def add_transaction_log(sender_id, receiver_id, size, time)
        @db.execute("INSERT INTO Transactions (sender_id, reciever_id, size, time) VALUES (?, ?, ?, ?)", sender_id, receiver_id, size, time)
    end

    def add_loan(user_id, loan_size)
        @db.execute("INSERT INTO Loan (size, amount_payed, start_time) VALUES (?, ?, ?)", loan_size, 0, Time.now.to_i)

        loan_id = @db.execute("SELECT last_insert_rowid()").first["last_insert_rowid()"]

        @db.execute("INSERT INTO User_loan_rel (user_id, loan_id) VALUES (?, ?)", user_id, loan_id)
    end

    def get_loans(**arguments)
        if arguments[:attribute] = "id"
            return @db.execute("SELECT * FROM Loan WHERE id = ?", arguments[:value])
        elsif arguments[:attribute] = "user_id"
            return @db.execute("SELECT * FROM User_loan_rel INNER JOIN Loan ON User_loan_rel.loan_id = Loan.id WHERE user_id = ?", arguments[:value])
        end

        return @db.execute("SELECT * FROM Loan")
    end


end

