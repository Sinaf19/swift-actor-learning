enum LedgerError: Error, CustomStringConvertible {
    case notEnoughFunds(available: Double, requested: Double)

    var description: String {
        switch self {
        case .notEnoughFunds(let available, let requested):
            return "requested \(requested), only \(available) available"
        }
    }
}
