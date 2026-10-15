import SwiftUI

@MainActor
final class HUDManager: ObservableObject {
    static let shared = HUDManager()

    @Published var folderPath: [(id: UUID, name: String)] = []
    @Published var feedbackMessage: String?
    @Published var feedbackIcon: String?
    @Published var isPeaking = false
    @Published var isPeakPaused = false
    @Published var peakProgress = 1.0
    @Published var peakingAssignments: [PeakItem] = []

    private var dismissTimer: Timer?
    private var countdownTimer: Timer?
    private var peakDuration: TimeInterval = 5
    private var peakElapsed: TimeInterval = 0
    private var lastTick = Date.now

    private init() {}

    // MARK: - Folder path

    func pushFolder(id: UUID, name: String) { folderPath.append((id: id, name: name)) }
    func popFolder() { if !folderPath.isEmpty { folderPath.removeLast() } }
    func clearFolderPath() { folderPath.removeAll() }
    func navigateFolderToDepth(_ depth: Int) {
        folderPath = depth < 0 ? [] : Array(folderPath.prefix(depth + 1))
    }

    // MARK: - Peak

    func peak(assignments: [PeakItem], duration: TimeInterval = 5) {
        peakingAssignments = assignments
        peakDuration = duration
        peakElapsed = 0
        peakProgress = 1.0
        isPeakPaused = false
        lastTick = .now
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPeaking = true }
        startCountdown()
    }

    func dismissPeak() {
        stopCountdown()
        withAnimation(.spring()) { isPeaking = false }
        peakProgress = 1.0
        isPeakPaused = false
    }

    func togglePeakPause() {
        isPeakPaused.toggle()
        if isPeakPaused {
            stopCountdown()
        } else {
            lastTick = .now
            startCountdown()
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdownTimer?.invalidate()
        let timer = Timer(timeInterval: 1 / 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    private func stopCountdown() { countdownTimer?.invalidate(); countdownTimer = nil }

    private func tick() {
        let now = Date.now
        peakElapsed += now.timeIntervalSince(lastTick)
        lastTick = now
        peakProgress = max(0, (peakDuration - peakElapsed) / peakDuration)
        if peakElapsed >= peakDuration { dismissPeak() }
    }

    // MARK: - Feedback

    func showFeedback(message: String, icon: String) {
        feedbackMessage = message
        feedbackIcon = icon
        dismissTimer?.invalidate()
        dismissTimer = .scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            withAnimation { self?.feedbackMessage = nil; self?.feedbackIcon = nil }
        }
    }
}

struct PeakItem: Identifiable {
    let key: NumpadKey
    let label: String

    var id: NumpadKey { key }
}
