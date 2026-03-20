struct Transaction {
    let id: Int
    let amount: Double
    let outcome: Outcome
    var succeeded: Bool {
        outcome.succeeded
    }
    var note: String {
        outcome.note
    }

    enum Outcome {
        case success
        case failure(reason: String)

        var note: String {
            switch self {
            case .success:
                return "OK"
            case .failure(let reason):
                return "FAILURE: \(reason)"
            }
        }

        var succeeded: Bool {
            if case .success = self {
                return true
            }
            return false
        }
    }
}
