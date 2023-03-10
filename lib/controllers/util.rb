def get_amount_remaining(loan_id)
    loan = $db.get_loans(attribute: "id", value: loan_id).first

    return loan["size"] - loan["amount_payed"]
end