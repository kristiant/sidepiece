import OSLog

extension Logger {
    init(category: String) {
        self.init(subsystem: "com.sidepiece.app", category: category)
    }
}
