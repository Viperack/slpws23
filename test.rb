string = "AAAAAAAAAAAA"
def display_iban(iban_string)
    iban_string.insert(5, " ")
    iban_string.insert(9, " )

    return iban_string
end

puts display_iban(string)