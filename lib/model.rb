require "bcrypt"
require "sqlite3"
require "sinatra"

require_relative "entities/user"
require_relative "entities/bank_account"
require_relative "entities/loan"
require_relative "entities/loan_invite"
require_relative "entities/interest"

class Database
  def initialize(path)
    @db = SQLite3::Database.new(path)
    @db.results_as_hash = true
  end

  def reset_database
    tables = %w[User_bank_account_rel User_loan_rel Bank_account Loan Transactions User]

    tables.each do |table|
      sql = "DELETE FROM #{table}"

      @db.execute(sql)
    end
  end

  # User
  def create_user(name, email, password, permission_level)
    password_digest = BCrypt::Password.create(password)

    sql = <<-SQL
      INSERT INTO User (name, email, password_digest, permission_level) 
      VALUES (?, ?, ?, ?)
    SQL

    @db.execute(sql, name, email, password_digest, permission_level)
  end

  def get_users(**attributes)
    if attributes[:email]
      sql = <<-SQL
        SELECT *
        FROM User 
        WHERE email = ?
      SQL

      user_hashes = @db.execute(sql, attributes[:email])
    end

    if attributes[:bank_account_id]
      sql = <<-SQL
        SELECT *
        FROM User_bank_account_rel
        WHERE bank_account_id = ?
      SQL

      user_hashes = @db.execute(sql, attributes[:bank_account_id])
    end

    if attributes[:loan_id]
      sql = <<-SQL
        SELECT *
        FROM User_loan_rel
        WHERE loan_id = ?
      SQL

      user_hashes = @db.execute(sql, attributes[:loan_id])
    end

    if user_hashes
      return Array.new(user_hashes.length) { |i| User.new(user_hashes[i]) }
    end

    []
  end

  #@todo def update_user()

  #@todo def delete_user()

  # User_bank_account_rel
  def create_user_bank_account_rel(user_id, bank_account_id)
    sql = <<-SQL
      INSERT INTO User_bank_account_rel (user_id, bank_account_id)
      VALUES (?, ?)
    SQL

    @db.execute(sql, user_id, bank_account_id)
  end

  def delete_user_bank_account_rel(**attributes)
    if attributes[:user_id]
      sql = <<-SQL
        DELETE FROM User_bank_account_rel
        WHERE user_id = ?
      SQL

      return @db.execute(sql, attributes[:user_id])
    end

    if attributes[:bank_account_id]
      sql = <<-SQL
        DELETE FROM User_bank_account_rel
        WHERE bank_account_id = ?
      SQL

      return @db.execute(sql, attributes[:bank_account_id])
    end

    nil
  end

  # Bank_account
  def generate_iban
    bban_num = Random.rand(100000000)
    iban = "GB" + bban_num.digits.sum.to_s + int_to_string(bban_num, 8)

    while get_bank_accounts(attribute: "iban", value: iban).length != 0
      bban_num = Random.rand(100000000)
      iban = "GB" + bban_num.digits.sum.to_s + int_to_string(bban_num, 8)
    end

    iban
  end

  def int_to_string(int, string_length)
    string = int.to_s

    (0...(string_length - string.length)).each { string = "0" + string }

    string
  end

  def get_last_insert_id
    sql = <<-SQL
      SELECT last_insert_rowid()
    SQL

    @db.execute(sql).first["last_insert_rowid()"]
  end

  def create_bank_account(user_id, interest, unlock_date, name, locked)
    iban = generate_iban

    sql = <<-SQL
      INSERT INTO Bank_account (balance, name, interest, unlock_date, iban, locked)
      VALUES (?, ?, ?, ?, ?, ?)
    SQL

    @db.execute(sql, 0, name, interest, unlock_date, iban, locked)

    bank_account_id = get_last_insert_id

    create_user_bank_account_rel(user_id, bank_account_id)

    bank_account_id
  end

  # Retrieves bank accounts from the database, with or without filtering attributes.
  #
  # @param **arguments [Hash]
  # @param attribute: [String] the attributes that banks accounts need to have a matching value on to be retrieved, `"id"`, `"user_id"` or `"iban"`.
  # @param value: [Int] the value of the attribute that banks accounts need to match to be retrieved.
  # @return [Array<Hash>] array of the retrieved bank accounts.
  def get_bank_accounts(**arguments)
    if arguments[:attribute]
      case arguments[:attribute]
      when "id", "iban"
        sql = <<-SQL
          SELECT *
          FROM Bank_account
          WHERE #{arguments[:attribute]} = ?
        SQL
      when "user_id"
        sql = <<-SQL
          SELECT * 
          FROM User_bank_account_rel 
          INNER JOIN Bank_account 
          ON User_bank_account_rel.bank_account_id = Bank_account.id 
          WHERE user_id = ?
        SQL
      end

      bank_accounts_as_hash = @db.execute(sql, arguments[:value])
    else
      sql = <<-SQL
        SELECT *
        FROM Bank_account
      SQL

      bank_accounts_as_hash = @db.execute(sql)
    end

    Array.new(bank_accounts_as_hash.length) { |i| Bank_account.new(bank_accounts_as_hash[i]) }
  end

  def negative_sum?(bank_account_id, transfer_size)
    get_bank_accounts(id: attributes[:id]) + attributes[:transfer_size] < 0
  end

  def update_bank_account(**attributes)
    if attributes[:id]
      return nil
    end

    if attributes[:balance] && attributes[:locked]
      return -1 if negative_sum?(attributes[:id], attributes[:balance])

      sql = <<-SQL
        UPDATE Bank_account
        SET balance = balance + ?, locked = ?
        WHERE id = ?
      SQL

      return @db.execute(sql, attributes[:balance], attributes[:locked], attributes[:id])
    end

    if attributes[:balance]
      return -1 if negative_sum?(attributes[:id], attributes[:balance])

      sql = <<-SQL
        UPDATE Bank_account
        SET balance = balance + ?
        WHERE id = ?
      SQL

      return @db.execute(sql, attributes[:balance], attributes[:id])
    end

    if attributes[:locked]
      sql = <<-SQL
        UPDATE Bank_account
        SET locked = ?
        WHERE id = ?
      SQL

      return @db.execute(sql, attributes[:locked], attributes[:id])
    end

    nil
  end

  def delete_bank_account(bank_account_id)
    sql = <<-SQL
      DELETE FROM User_bank_account_rel
      WHERE bank_account_id = ?
    SQL

    @db.execute(sql, bank_account_id)

    sql = <<-SQL
      DELETE FROM Bank_account
      WHERE id = ?
    SQL

    @db.execute(sql, bank_account_id)
  end

  # User_loan_rel
  def create_user_loan_rel(user_id, loan_id)
    sql = <<-SQL
      INSERT INTO User_loan_rel (user_id, loan_id)
      VALUES (?, ?)
    SQL

    @db.execute(sql, user_id, loan_id)
  end

  def delete_user_loan_rel(**attributes)
    if attributes[:user_id]
      sql = <<-SQL
        DELETE FROM User_loan_rel
        WHERE user_id = ?
      SQL

      return @db.execute(sql, attributes[:user_id])
    end

    if attributes[:loan_id]
      sql = <<-SQL
        DELETE FROM User_loan_rel
        WHERE loan_id = ?
      SQL

      return @db.execute(sql, attributes[:loan_id])
    end

    nil
  end

  # Interest
  def get_interest(type)
    sql = <<-SQL
      SELECT *
      FROM Interest
      WHERE type = ?
    SQL

    interests_as_hash = @db.execute(sql, type)

    Array.new(interests_as_hash.length) { |i| Interest.new(interests_as_hash[i]) }
  end

  # TODO update_interest()

  # Loan
  def create_loan(user_id, loan_size)
    sql = <<-SQL
      INSERT INTO Loan (size, amount_payed, start_time, interest)
      VALUES (?, ?, ?, ?)
    SQL

    rate = get_interest("Loan").first.rate

    @db.execute(sql, loan_size, 0, Time.now.to_i, rate)

    loan_id = get_last_insert_id

    create_user_loan_rel(user_id, loan_id)

    loan_id
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

      loans_as_hashes = @db.execute(sql, arguments[:value])
    else
      sql = <<-SQL
        SELECT *
        FROM Loan
      SQL

      loans_as_hashes = @db.execute(sql)
    end

    Array.new(loans_as_hashes.length) { |i| Loan.new(loans_as_hashes[i]) }
  end

  def loan_fully_paid?(loan_id)
    loan = get_loans(attribute: "id", value: loan_id)

    loan["amount_payed"] >= loan["size"]
  end

  def update_loan(loan_id, size)
    if get_loans(attribute: "id", value: loan_id).first.balance + size < 0
      return nil
    end

    sql = <<-SQL
      UPDATE Loan
      SET amount_payed = amount_payed + ?
      WHERE id = ?
    SQL

    @db.execute(sql, size, loan_id)

    if loan_fully_paid?(loan_id)
      delete_loan(loan_id)
    end
  end

  def delete_loan(loan_id)
    sql = <<-SQL
      DELETE FROM User_loan_rel
      WHERE loan_id = ?
    SQL

    @db.execute(sql, loan_id)

    sql = <<-SQL
      DELETE FROM Loan
      WHERE id = ?
    SQL

    @db.execute(sql, loan_id)
  end

  # Loan invite

  def create_loan_invite(user_id, loan_id)
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

    loan_invites_as_hash = @db.execute(sql, user_id)

    Array.new(loan_invites_as_hash.length) { |i| Loan_invite.new(loan_invites_as_hash[i]) }
  end

  # Transaction
  def create_transaction_log(sender_id, receiver_id, size, time)
    sql = <<-SQL
      INSERT INTO Transactions (sender_id, receiver_id, size, time)
      VALUES (?, ?, ?, ?)
    SQL

    @db.execute(sql, sender_id, receiver_id, size, time)

  end

  # TODO get_transactions_logs()
end
