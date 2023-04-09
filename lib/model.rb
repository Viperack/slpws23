require "bcrypt"
require "sqlite3"
require "sinatra"
require "sinatra/reloader"

require_relative "entities/user"
require_relative "entities/bank_account"
require_relative "entities/loan"
require_relative "entities/loan_invite"
require_relative "entities/interest"
require_relative "entities/transaction"

class Database
  # Initializes the database
  #
  # @param [String] path The path to the database
  #
  # @return [void]
  def initialize(path)
    @db = SQLite3::Database.new(path)
    @db.results_as_hash = true
  end

  # Empties the database of all data
  #
  # @return [void]
  def reset_database
    tables = %w[User_bank_account_rel User_loan_rel Bank_account Loan Transactions User]

    tables.each do |table|
      sql = "DELETE FROM #{table}"

      @db.execute(sql)
    end
  end

  # Inserts a user into the database
  #
  # @param [String] name The username
  # @param [String] email The users email adress
  # @param [String] password The users password
  # @param [Integer] permission_level The users permission level
  #
  # @return [void]
  def create_user(name, email, password, permission_level)
    password_digest = BCrypt::Password.create(password)

    sql = <<-SQL
      INSERT INTO User (name, email, password_digest, permission_level) 
      VALUES (?, ?, ?, ?)
    SQL

    @db.execute(sql, name, email, password_digest, permission_level)
  end

  # Retrieves users from the database and can filter on a number of attributes
  #
  # @param [Hash] arguments
  # @option arguments [String] email The wished email that is wished to be used for the filtering
  # @option arguments [String] id The wished id that is wished to be used for the filtering
  # @option arguments [Integer] bank_account_id The wished bank_account_id that is wished to be used for the filtering
  # @option arguments [Integer] loan_id The wished loan_id that is wished to be used for the filtering
  #
  # @return [Array<User>] Array of the retrieved users.
  def get_users(**arguments)
    if arguments[:email]
      sql = <<-SQL
        SELECT *
        FROM User 
        WHERE email = ?
      SQL

      user_hashes = @db.execute(sql, arguments[:email])
    end

    if arguments[:id]
      sql = <<-SQL
        SELECT *
        FROM User 
        WHERE id = ?
      SQL

      user_hashes = @db.execute(sql, arguments[:id])
    end

    if arguments[:bank_account_id]
      sql = <<-SQL
        SELECT *
        FROM User_bank_account_rel
        WHERE bank_account_id = ?
      SQL

      user_hashes = @db.execute(sql, arguments[:bank_account_id])
    end

    if arguments[:loan_id]
      sql = <<-SQL
        SELECT *
        FROM User_loan_rel
        WHERE loan_id = ?
      SQL

      user_hashes = @db.execute(sql, arguments[:loan_id])
    end

    if user_hashes
      return Array.new(user_hashes.length) { |i| User.new(user_hashes[i]) }
    end

    []
  end

  #@todo def update_user()

  #@todo def delete_user()

  # Inserts a user_bank_account_rel into the database
  #
  # @param [Integer] user_id The user_id
  # @param [Integer] bank_account_id The bank_account_id
  #
  # @return [void]
  def create_user_bank_account_rel(user_id, bank_account_id)
    sql = <<-SQL
      INSERT INTO User_bank_account_rel (user_id, bank_account_id)
      VALUES (?, ?)
    SQL

    @db.execute(sql, user_id, bank_account_id)
  end

  # Deletes a user_bank_account relationship
  #
  # @param [Integer] user_id The user_id that is wished to be used for the filtering to delete
  # @param [Integer] bank_account_id The bank_account_id that is wished to be used for the filtering to delete
  #
  # @return [void]
  def delete_user_bank_account_rel(**arguments)
    if arguments[:user_id]
      sql = <<-SQL
        DELETE FROM User_bank_account_rel
        WHERE user_id = ?
      SQL

      return @db.execute(sql, arguments[:user_id])
    end

    if arguments[:bank_account_id]
      sql = <<-SQL
        DELETE FROM User_bank_account_rel
        WHERE bank_account_id = ?
      SQL

      return @db.execute(sql, arguments[:bank_account_id])
    end

    nil
  end

  # Generates a guaranteed new iban
  #
  # @return [String] The iban
  def generate_iban
    bban_num = Random.rand(100000000)
    iban = "GB" + bban_num.digits.sum.to_s + int_to_string(bban_num, 8)

    while get_bank_accounts(iban: iban).length != 0
      bban_num = Random.rand(100000000)
      iban = "GB" + bban_num.digits.sum.to_s + int_to_string(bban_num, 8)
    end

    iban
  end

  # Generate string from an integer which a certain amounts of preceding zeros
  #
  # @param [Integer] int The number that is supposed to be in the string
  # @param [Integer] string_length The amount of zeros that are supposed to precede the number
  #
  # @return [String] A string of the number with the zeros
  def int_to_string(int, string_length)
    string = int.to_s

    (0...(string_length - string.length)).each { string = "0" + string }

    string
  end

  # Gets the id of the last insert to the database
  #
  # @return [Int] The id of the last insert
  def get_last_insert_id
    sql = <<-SQL
      SELECT last_insert_rowid()
    SQL

    @db.execute(sql).first["last_insert_rowid()"]
  end

  # Inserts a bank_account into the database
  #
  # @param [Integer] user_id The user_id
  # @param [Integer] interest The interest rate of the bank account
  # @param [Integer] unlock_date The unlock date of the bank account in epoch
  # @param [Integer] name The name of the bank account
  # @param [Integer] locked Whether the bank account is locked or not, 0 = unlocked, 1 = locked
  #
  # @return [void]
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

  # Retrieves bank accounts from the database and can filter on a number of attributes
  #
  # @param [Hash] arguments
  # @option arguments [Integer] id The wished bank_account_id that is wished to be used for the filtering
  # @option arguments [String] iban The wished iban that is wished to be used for the filtering
  # @option arguments [Integer] user_id The wished user_id that is wished to be used for the filtering
  # @return [Array<Bank_account>] Array of the retrieved bank accounts.
  def get_bank_accounts(**arguments)
    if arguments[:id]
      sql = <<-SQL
          SELECT *
          FROM Bank_account
          WHERE id = ?
      SQL

      bank_accounts_as_hash = @db.execute(sql, arguments[:id])
      return Array.new(bank_accounts_as_hash.length) { |i| Bank_account.new(bank_accounts_as_hash[i]) }
    end

    if arguments[:iban]
      sql = <<-SQL
          SELECT *
          FROM Bank_account
          WHERE iban = ?
      SQL

      bank_accounts_as_hash = @db.execute(sql, arguments[:iban])
      return Array.new(bank_accounts_as_hash.length) { |i| Bank_account.new(bank_accounts_as_hash[i]) }
    end

    if arguments[:user_id]
      sql = <<-SQL
          SELECT * 
          FROM User_bank_account_rel 
          INNER JOIN Bank_account 
          ON User_bank_account_rel.bank_account_id = Bank_account.id 
          WHERE user_id = ?
      SQL

      bank_accounts_as_hash = @db.execute(sql, arguments[:user_id])
      return Array.new(bank_accounts_as_hash.length) { |i| Bank_account.new(bank_accounts_as_hash[i]) }
    end

    sql = <<-SQL
        SELECT *
        FROM Bank_account
    SQL

    bank_accounts_as_hash = @db.execute(sql)
    Array.new(bank_accounts_as_hash.length) { |i| Bank_account.new(bank_accounts_as_hash[i]) }
  end

  # Checks if the transfer is larger than the balance of the bank account
  #
  # @param [Integer] bank_account_id The bank account id
  # @param [Integer] transfer_size The size of the transfer
  #
  # @return [TrueClass or FalseClass] Whether the condition is true or false
  def negative_sum?(bank_account_id, transfer_size)
    get_bank_accounts(id: bank_account_id).first.balance + transfer_size < 0
  end

  # Retrieves bank accounts from the database and can filter on a number of attributes
  #
  # @param [Hash] arguments
  # @option arguments [Integer] id The wished bank_account_id that is wished to be used for the filtering
  # @option arguments [String] iban The wished iban that is wished to be used for the filtering
  # @option arguments [Integer] user_id The wished user_id that is wished to be used for the filtering
  # @return [Array<Bank_account>] Array of the retrieved bank accounts.
  def update_bank_account(**arguments)
    if !arguments[:id]
      return nil
    end

    if arguments[:balance] && arguments[:locked]
      return -1 if negative_sum?(arguments[:id], arguments[:balance])

      sql = <<-SQL
        UPDATE Bank_account
        SET balance = balance + ?, locked = ?
        WHERE id = ?
      SQL

      return @db.execute(sql, arguments[:balance], arguments[:locked], arguments[:id])
    end

    if arguments[:balance]
      return -1 if negative_sum?(arguments[:id], arguments[:balance])

      sql = <<-SQL
        UPDATE Bank_account
        SET balance = balance + ?
        WHERE id = ?
      SQL

      return @db.execute(sql, arguments[:balance], arguments[:id])
    end

    if arguments[:locked]
      sql = <<-SQL
        UPDATE Bank_account
        SET locked = ?
        WHERE id = ?
      SQL

      return @db.execute(sql, arguments[:locked], arguments[:id])
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

  def get_user_id_from_loan_rel(loan_id)
    sql = <<-SQL
      SELECT user_id
      FROM User_loan_rel
      WHERE loan_id = ?
    SQL

    return @db.execute(sql, loan_id)
  end

  def delete_user_loan_rel(**arguments)
    if arguments[:user_id]
      sql = <<-SQL
        DELETE FROM User_loan_rel
        WHERE user_id = ?
      SQL

      return @db.execute(sql, arguments[:user_id])
    end

    if arguments[:loan_id]
      sql = <<-SQL
        DELETE FROM User_loan_rel
        WHERE loan_id = ?
      SQL

      return @db.execute(sql, arguments[:loan_id])
    end

    nil
  end

  # Interest
  def get_interest(**arguments)

    case arguments[:type]
    when "Loan", "Savings"
      sql = <<-SQL
        SELECT *
        FROM Interest
        WHERE type = ?
      SQL

      interests_as_hash = @db.execute(sql, arguments[:type])
    when nil
      sql = <<-SQL
        SELECT *
        FROM Interest
      SQL

      interests_as_hash = @db.execute(sql)
    end


    Array.new(interests_as_hash.length) { |i| Interest.new(interests_as_hash[i]) }
  end

  def update_interest(**arguments)
    if !arguments[:id]
      return -1
    end

    if arguments[:rate] && arguments[:time_deposit]
      sql = <<-SQL
      UPDATE Interest
      SET rate = ?, time_deposit = ?
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:rate], arguments[:time_deposit], arguments[:id])

      return 0
    end

    if arguments[:rate]
      sql = <<-SQL
      UPDATE Interest
      SET rate = ?
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:rate], arguments[:id])

      return 0
    end

    if arguments[:time_deposit]
      sql = <<-SQL
      UPDATE Interest
      SET time_deposit = ?
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:time_deposit], arguments[:id])

      return 0
    end

    return nil
  end

  # Loan
  def create_loan(user_id, loan_size)
    sql = <<-SQL
      INSERT INTO Loan (size, amount_payed, interest_payment_date, interest)
      VALUES (?, ?, ?, ?)
    SQL

    rate = get_interest(type: "Loan").first.rate

    @db.execute(sql, loan_size, 0, (Time.now.to_i + 31556926), rate)

    loan_id = get_last_insert_id

    create_user_loan_rel(user_id, loan_id)

    loan_id
  end

  def get_loans(**arguments)
    if arguments[:id]
      sql = <<-SQL
          SELECT *
          FROM Loan
          WHERE id = ?
      SQL

      loans_as_hashes = @db.execute(sql, arguments[:id])
      return Array.new(loans_as_hashes.length) { |i| Loan.new(loans_as_hashes[i]) }
    end

    if arguments[:user_id]
      sql = <<-SQL
          SELECT *
          FROM User_loan_rel
          INNER JOIN Loan
          ON User_loan_rel.loan_id = Loan.id
          WHERE user_id = ?
      SQL

      loans_as_hashes = @db.execute(sql, arguments[:user_id])
      return Array.new(loans_as_hashes.length) { |i| Loan.new(loans_as_hashes[i]) }
    end

    sql = <<-SQL
        SELECT *
        FROM Loan
    SQL

    loans_as_hashes = @db.execute(sql)
    Array.new(loans_as_hashes.length) { |i| Loan.new(loans_as_hashes[i]) }
  end

  def loan_fully_paid?(loan_id)
    loan = get_loans(id: loan_id).first

    loan.amount_payed >= loan.size
  end

  def loan_expired?(loan_id)
    loan = $db.get_loans(id: loan_id).first

    return loan.interest_payment_date <= Time.now.to_i
  end

  def update_loan(**arguments)
    if arguments[:size] && arguments[:amount_payed]
      loan = get_loans(id: arguments[:id]).first
      if loan.amount_payed + arguments[:amount_payed] > arguments[:size]
        return nil
      end

      sql = <<-SQL
      UPDATE Loan
      SET size = size + ?, amount_payed = amount_payed + ?
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:size], arguments[:size], arguments[:id])
    end

    if arguments[:size]
      sql = <<-SQL
      UPDATE Loan
      SET size = size + ?
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:size], arguments[:id])
    end

    if arguments[:amount_payed]
      loan = get_loans(id: arguments[:id]).first
      if loan.amount_payed + arguments[:amount_payed] > loan.size
        return nil
      end

      sql = <<-SQL
      UPDATE Loan
      SET amount_payed = amount_payed + ?
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:amount_payed], arguments[:id])
    end

    if loan_expired?(arguments[:id])
      sql = <<-SQL
      UPDATE Loan
      SET interest_payment_date = interest_payment_date + 31556926
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:id])
    end

    if loan_fully_paid?(arguments[:id])
      delete_loan(arguments[:id])
    end

    return nil
  end

  def delete_loan(loan_id)
    delete_loan_invite(loan_id: loan_id)

    delete_user_loan_rel(loan_id: loan_id)

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

  def delete_loan_invite(**arguments)
    if arguments[:id]
      sql = <<-SQL
      DELETE FROM Loan_invite
      WHERE id = ?
      SQL

      @db.execute(sql, arguments[:id])
    end

    if arguments[:loan_id]
      sql = <<-SQL
      DELETE FROM Loan_invite
      WHERE loan_id = ?
      SQL

      @db.execute(sql, arguments[:loan_id])
    end


  end

  # Transaction
  def create_transaction_log(sender_id, receiver_id, size, time)
    puts "#{sender_id} sent #{receiver_id}, $#{size} at #{time}"

    sql = <<-SQL
      INSERT INTO Transactions (sender_id, receiver_id, size, time)
      VALUES (?, ?, ?, ?)
    SQL

    @db.execute(sql, sender_id, receiver_id, size, time)
  end

  def get_transactions_logs
    sql = <<-SQL
      SELECT *
      FROM Transactions
    SQL

    transactions_as_hash = @db.execute(sql)
    Array.new(transactions_as_hash.length) { |i| Transaction.new(transactions_as_hash[i]) }
  end
end
