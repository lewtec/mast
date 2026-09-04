enum ServerStatus: Equatable {
    case stopped
    case starting
    case running
    case failed

    var label: String {
        switch self {
        case .stopped: "Server stopped"
        case .starting: "Starting server"
        case .running: "Server running"
        case .failed: "Server failed"
        }
    }
}
