require "sinatra"

sql = <<-SQL
SELECT *
FROM Bank_account
WHERE #{"id"} = ?
SQL

puts sql