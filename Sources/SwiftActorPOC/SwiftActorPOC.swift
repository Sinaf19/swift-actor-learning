// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct SwiftActorPOC {
    static func main() async {
        let alice = BankAccount(owner: "Alice", balance: 1000.0)
        let bob = BankAccount(owner: "Bob", balance: 500.0)
        let log = TransactionLog(transactions: [])

        await withTaskGroup(of: Void.self) {
            group in
            for i in 0 ..< 10 {
                group.addTask {
                    await transferFunds(amount: 150, from: alice, to: bob, log: log, id: i)
                }
            }
        }

        print("Alice's balance: \(await alice.balance)")
        print("Bob's balance: \(await bob.balance)")
        print("Total transfers: \(await log.count)")
        print("Successes: \(await log.successCount)")
        print("Failures: \(await log.failureCount)")
        for tx in await log.all {
            print("  [\(tx.id)] \(tx.amount) — \(tx.note)")
        }
    }
}

func transferFunds(amount: Double, from: BankAccount, to: BankAccount, log: TransactionLog, id: Int) async {
    do {
        try await from.withdraw(amount)
        await to.deposit(amount)
        await log.record(Transaction(id: id, amount: amount, outcome: .success))
    } catch let error as LedgerError {
        await log.record(Transaction(id: id, amount: amount, outcome: .failure(reason: error.description)))
    } catch {
        print("Error")
    }
}
