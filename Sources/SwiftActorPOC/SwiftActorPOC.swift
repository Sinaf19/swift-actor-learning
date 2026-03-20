// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct SwiftActorPOC {
    static func main() {
        let account = BankAccount(owner: "Alice", balance: 1000.0)
        var tasks: [Task<()?, Never>] = []

        for _ in 0..<10 {
            let task = Task {
                try? account.withdraw(50)
            }
        tasks.append(task)
        }

        for task in tasks {
            await task.value
        }
        print("Final balance: \(account.balance)")
    }
}
