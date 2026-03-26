actor TransactionLog {
    private var transactions: [Transaction]

    init(transactions: [Transaction]) {
        self.transactions = transactions
    }

    func record(_ tx: Transaction) {
        transactions.append(tx)
    }

    var count: Int {
        transactions.count
    }

    var successCount: Int {
        transactions.filter({ $0.succeeded }).count
    }

    var failureCount: Int {
        transactions.filter({ !$0.succeeded }).count
    }

    var all: [Transaction] {
        transactions
    }



}