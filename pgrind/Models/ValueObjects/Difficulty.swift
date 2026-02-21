enum Difficulty: String, Codable, CaseIterable, CustomStringConvertible {
    case notAttempted
    case easy
    case medium
    case hard

    var description: String {
        switch self {
        case .notAttempted: return "Not Attempted"
        case .easy:         return "Easy"
        case .medium:       return "Medium"
        case .hard:         return "Hard"
        }
    }
}
