class BankAccount: Equatable {
    let owner: String
    var balance: Double

    init(owner: String, balance: Double = 0.0) {
        self.owner = owner
        self.balance = balance
    }

    func deposit(_ amount: Double) {
        balance += amount
    }

    func withdraw(_ amount: Double) throws {
        if amount < balance {
            balance -= amount
        } else {
            throw LedgerError.notEnoughFunds(available: balance, requested: amount)
        }
    }

    static func == (lhs: BankAccount, rhs: BankAccount) -> Bool {
        return lhs.owner == rhs.owner && lhs.balance == rhs.balance
    }
}
