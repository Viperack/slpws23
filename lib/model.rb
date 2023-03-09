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

    def get_last_insert_id()
        sql = <<-SQL
            SELECT last_insert_rowid()
        SQL

        @db.execute(sql).first["last_insert_rowid()"]
    end

    def wipe_all()
        tables = ["User_bank_account_rel", "User_loan_rel", "Bank_account", "Loan", "Transactions", "User"]

        for table in tables
            sql = "DELETE FROM #{table}"
            puts sql

            @db.execute(sql)
        end
    end

    def add_user_to_bank_account(user_id, bank_account_id)
        sql = <<-SQL
            INSERT INTO User_bank_account_rel (user_id, bank_account_id)
            VALUES (?, ?)
        SQL

        @db.execute(sql, user_id, bank_account_id)
    end

    def add_user(name, email, password)
        password_digest = BCrypt::Password.create(password)

        sql = <<-SQL
            INSERT INTO User (name, email, password) 
            VALUES (?, ?, ?)
        SQL

        @db.execute(sql, name, email, password_digest)
    end

    def get_user(email)
        sql = <<-SQL
            SELECT *
            FROM User 
            WHERE email = ?
        SQL

        @db.execute(sql, email).first
    end

    # Retrievs bank accounts from the database, with or without filtering attributes.
    #
    # @param where [String] the attributes that banks accounts need to have a matching value on to be retrieved, `"id"`, `"user_id"` or `"iban"`.
    # @param where [String] the value of the attribute that banks accounts need to match to be retrieved.
    # @return [Array<Hash>] array of the retrieved bank accounts.
    def get_bank_accounts(**arguments)
        if ["id", "iban", "user_id"].include?(arguments[:attribute]) 
            if arguments[:attribute] == "user_id"
                sql = <<-SQL
                    SELECT * 
                    FROM User_bank_account_rel 
                    INNER JOIN Bank_account 
                    ON User_bank_account_rel.bank_account_id = Bank_account.id 
                    WHERE user_id = ?
                SQL
            else
                sql = <<-SQL
                    SELECT *
                    FROM Bank_account
                    WHERE #{arguments[:attribute]} = ?
                SQL
            end

            return @db.execute(sql, arguments[:value])
        end

        sql = <<-SQL
            SELECT *
            FROM Bank_account
        SQL

        return @db.execute(sql)
    end

    def get_id_from_iban(iban)
        sql = <<-SQL
            SELECT id
            FROM Bank_account
            WHERE iban = ?
        SQL

        response = @db.execute(sql, iban)

        if response.length == 0
            return nil
        end

        return response.first["id"]
    end

    def add_bank_account(user_id, interest, unlock_date, name, locked)
        bban = Random.rand(100000000)
        bban_string = "GB" + bban.digits.sum.to_s + int_to_string(bban, 8)

        while get_bank_accounts(attribute: "iban", value: bban_string).length != 0
            bban = Random.rand(100000000)
            bban_string = "GB" + bban.digits.sum.to_s + int_to_string(bban, 8)
            puts bban_string
            p get_bank_accounts(attribute: "iban", value: bban_string).length
        end

        iban = bban_string

        sql = <<-SQL
            INSERT INTO Bank_account (balance, name, interest, unlock_date, iban, locked)
            VALUES (?, ?, ?, ?, ?, ?)
        SQL

        @db.execute(sql, 0, name, interest, unlock_date, iban, locked)

        bank_account_id = get_last_insert_id()

        add_user_to_bank_account(user_id, bank_account_id)

        return bank_account_id
    end

    def update_balance(bank_account_id, size)
        if get_bank_accounts(attribute: "id", value: bank_account_id).first["balance"] + size < 0
            return nil
        end

        sql = <<-SQL
            UPDATE Bank_account
            SET balance = balance + ?
            WHERE id = ?
        SQL

        @db.execute(sql, size, bank_account_id)
    end

    def close_bank_account(bank_account_id)
        sql = <<-SQL
            DELETE FROM Bank_account
            WHERE id = ?
        SQL

        @db.execute(sql, bank_account_id)

        sql = <<-SQL
            DELETE FROM User_bank_account_rel
            WHERE bank_account_id = ?
        SQL

        @db.execute(sql, bank_account_id)
    end

    def get_interest_rates(type)
        sql = <<-SQL
            SELECT *
            FROM Interest_rate
            WHERE type = ?
        SQL
        
        @db.execute(sql, type)
    end

    def update_lock(bank_account_id, locked)
        sql = <<-SQL
            UPDATE Bank_account
            SET locked = ?
            WHERE id = ?
        SQL

        @db.execute(sql, locked, bank_account_id)
    end

    def add_transaction_log(sender_id, receiver_id, size, time)
        sql = <<-SQL
            INSERT INTO Transactions (sender_id, reciever_id, size, time)
            VALUES (?, ?, ?, ?)
        SQL
        
        @db.execute(sql, sender_id, receiver_id, size, time)
    end

    def add_loan(user_id, loan_size)
        sql = <<-SQL
            INSERT INTO Loan (size, amount_payed, start_time, interest)
            VALUES (?, ?, ?, ?)
        SQL

        interest = get_interest_rates("Loan").first["interest"]

        @db.execute(sql, loan_size, 0, Time.now.to_i, interest)

        loan_id = get_last_insert_id()

        add_user_to_loan(user_id, loan_id)

        return loan_id
    end

    def add_user_to_loan(user_id, loan_id)
        sql = <<-SQL
            INSERT INTO User_loan_rel (user_id, loan_id)
            VALUES (?, ?)
        SQL

        @db.execute(sql, user_id, loan_id)
    end

    def get_loans(**arguments)
        if arguments[:attribute]
            case arguments[:attribute]
            when "id"
                sql = <<-SQL
                    SELECT *
                    FROM Loan
                    WHERE id = ?
                SQL
            when "user_id"
                sql = <<-SQL
                    SELECT *
                    FROM User_loan_rel
                    INNER JOIN Loan
                    ON User_loan_rel.loan_id = Loan.id
                    WHERE user_id = ?
                SQL
            end

            return @db.execute(sql, arguments[:value]) 
        end

        sql = <<-SQL
            SELECT *
            FROM Loan
        SQL

        return @db.execute(sql)
    end

    def add_user_invite_to_loan(user_id, loan_id)
        sql = <<-SQL
            INSERT INTO Loan_invite (user_id, loan_id)
            VALUES (?, ?)
        SQL

        @db.execute(sql, user_id, loan_id)
    end

    def get_loan_invites(user_id)
        sql = <<-SQL
            SELECT *
            FROM Loan_invite
            WHERE user_id = ?
        SQL
    
        @db.execute(sql, user_id)
    end
end
