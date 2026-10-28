import OSLog

/// The only place concrete services are created and wired together.
@MainActor
final class CompositionRoot {
    static let shared = CompositionRoot()

    private let logger = Logger(subsystem: "com.kutluhangul.lunula", category: "app")

    func start() {
        logger.info("start")
    }
}
