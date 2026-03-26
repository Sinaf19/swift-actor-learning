// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct SwiftActorPOC {
    static func main() async {
        let account = BankAccount(owner: "Alice", balance: 1000.0)
        let log = TransactionLog(transactions: [])
        let transaction = Transaction(id: 1, amount: 3.0, outcome: Transaction.Outcome.success, attachment: NoteAttachment())

        await log.record(transaction)

        var tasks: [Task<()?, Never>] = []

        for _ in 0 ..< 50 {
            let task = Task.detached {
                try? await account.withdraw(5)
            }
            tasks.append(task)
        }

        print(account.describe())

        for task in tasks {
            await task.value
        }
        print("Final balance: \(await account.balance)")
    }
}
