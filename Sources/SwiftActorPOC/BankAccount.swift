actor BankAccount {
    let owner: String
    var balance: Double

    init(owner: String, balance: Double = 0.0) {
        self.owner = owner
        self.balance = balance
    }

    func deposit(_ amount: Double) {
        balance += amount
    }

    nonisolated func describe() -> String {
        return "BankAccount(owner: \(owner))"
    }

    func withdraw(_ amount: Double) throws {
        if amount < balance {
            balance -= amount
        } else {
            throw LedgerError.notEnoughFunds(available: balance, requested: amount)
        }
    }
}
