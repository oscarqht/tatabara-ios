import Combine
import Foundation

@MainActor
final class TimerEngine: ObservableObject {
    @Published private(set) var session: TimerSession?
    @Published private(set) var snapshot: TimerSessionSnapshot?

    private let audioCoordinator: SessionAudioControlling
    private let activitySyncer: SessionActivitySyncing
    private var ticker: AnyCancellable?
    private var audioSyncTask: Task<Void, Never>?

    init(
        audioCoordinator: SessionAudioControlling = SessionAudioCoordinator(),
        activitySyncer: SessionActivitySyncing = NoopSessionActivitySyncer()
    ) {
        self.audioCoordinator = audioCoordinator
        self.activitySyncer = activitySyncer
    }

    var hasActiveSession: Bool {
        guard let snapshot else { return false }
        return snapshot.phase != .completed
    }

    func start(with preset: WorkoutPreset, now: Date = .now) {
        let segments = Self.buildSegments(from: preset)
        guard let first = segments.first else { return }

        session = TimerSession(
            preset: preset,
            segments: segments,
            currentSegmentIndex: 0,
            phaseStartDate: now,
            phaseEndDate: now.addingTimeInterval(first.durationSeconds),
            isPaused: false,
            pausedRemainingDuration: nil,
            completedAt: nil
        )

        publishSnapshot(now: now)
        startTicker()
        requestAudioSync()
    }

    func togglePauseResume(now: Date = .now) {
        guard let session else { return }
        session.isPaused ? resume(now: now) : pause(now: now)
    }

    func pause(now: Date = .now) {
        synchronize(now: now)
        guard var session else { return }

        session.isPaused = true
        session.pausedRemainingDuration = max(session.phaseEndDate.timeIntervalSince(now), 0)
        self.session = session

        ticker?.cancel()
        publishSnapshot(now: now)
        requestAudioSync()
    }

    func resume(now: Date = .now) {
        guard var session, let remaining = session.pausedRemainingDuration else { return }
        let currentDuration = currentSegment?.durationSeconds ?? remaining

        session.isPaused = false
        session.pausedRemainingDuration = nil
        session.phaseEndDate = now.addingTimeInterval(remaining)
        session.phaseStartDate = session.phaseEndDate.addingTimeInterval(-currentDuration)
        self.session = session

        publishSnapshot(now: now)
        startTicker()
        requestAudioSync()
    }

    func restartCurrentPhase(now: Date = .now) {
        guard var session, let currentSegment else { return }

        session.isPaused = false
        session.pausedRemainingDuration = nil
        session.phaseStartDate = now
        session.phaseEndDate = now.addingTimeInterval(currentSegment.durationSeconds)
        self.session = session

        publishSnapshot(now: now)
        startTicker()
        requestAudioSync()
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        session = nil
        snapshot = nil
        activitySyncer.update(snapshot: nil)
        requestAudioSync()
    }

    func synchronize(now: Date = .now) {
        guard var session else { return }

        if session.isPaused {
            self.session = session
            publishSnapshot(now: now)
            return
        }

        while session.currentSegmentIndex < session.segments.count, now >= session.phaseEndDate {
            let nextIndex = session.currentSegmentIndex + 1

            if nextIndex >= session.segments.count {
                session.completedAt = session.phaseEndDate
                self.session = session
                let completedSnapshot = makeCompletedSnapshot(from: session)
                snapshot = completedSnapshot
                activitySyncer.update(snapshot: completedSnapshot)
                ticker?.cancel()
                ticker = nil
                requestAudioSync()
                return
            }

            let nextSegment = session.segments[nextIndex]
            session.currentSegmentIndex = nextIndex
            session.phaseStartDate = session.phaseEndDate
            session.phaseEndDate = session.phaseStartDate.addingTimeInterval(nextSegment.durationSeconds)
        }

        self.session = session
        publishSnapshot(now: now)
    }

    func handleScenePhaseDidChange() {
        synchronize()
    }

    func remainingSegments() -> [SessionSegment] {
        guard let session, session.currentSegmentIndex < session.segments.count else { return [] }
        return Array(session.segments.dropFirst(session.currentSegmentIndex))
    }

    static func buildSegments(from preset: WorkoutPreset) -> [SessionSegment] {
        guard preset.cycleCount > 0 else { return [] }

        var segments: [SessionSegment] = []

        for cycle in 1...preset.cycleCount {
            segments.append(SessionSegment(phase: .work, durationSeconds: TimeInterval(preset.workDurationSeconds), cycleIndex: cycle))

            guard cycle < preset.cycleCount else { continue }

            segments.append(SessionSegment(phase: .rest, durationSeconds: TimeInterval(preset.restDurationSeconds), cycleIndex: cycle))
        }

        return segments
    }

    private var currentSegment: SessionSegment? {
        guard let session, session.currentSegmentIndex < session.segments.count else { return nil }
        return session.segments[session.currentSegmentIndex]
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.synchronize(now: now)
            }
    }

    private func publishSnapshot(now: Date) {
        guard let session else {
            snapshot = nil
            activitySyncer.update(snapshot: nil)
            return
        }

        let currentSegment = session.segments[session.currentSegmentIndex]
        let duration = currentSegment.durationSeconds
        let elapsed: TimeInterval
        let remaining: TimeInterval

        if session.isPaused {
            remaining = session.pausedRemainingDuration ?? duration
            elapsed = max(duration - remaining, 0)
        } else {
            elapsed = min(max(now.timeIntervalSince(session.phaseStartDate), 0), duration)
            remaining = max(session.phaseEndDate.timeIntervalSince(now), 0)
        }

        let nextPhaseInfo = nextMeaningfulPhase(after: session.currentSegmentIndex, in: session.segments)
        let newSnapshot = TimerSessionSnapshot(
            preset: session.preset,
            phase: currentSegment.phase,
            currentCycle: currentSegment.cycleIndex,
            totalCycles: session.preset.cycleCount,
            phaseStartDate: session.phaseStartDate,
            phaseEndDate: session.phaseEndDate,
            phaseDuration: duration,
            elapsedSeconds: elapsed,
            remainingSeconds: remaining,
            progress: duration > 0 ? min(max(elapsed / duration, 0), 1) : 1,
            isPaused: session.isPaused,
            nextPhase: nextPhaseInfo?.phase,
            nextPhaseDuration: nextPhaseInfo?.durationSeconds
        )

        snapshot = newSnapshot
        activitySyncer.update(snapshot: newSnapshot)
    }

    private func makeCompletedSnapshot(from session: TimerSession) -> TimerSessionSnapshot {
        TimerSessionSnapshot(
            preset: session.preset,
            phase: .completed,
            currentCycle: session.preset.cycleCount,
            totalCycles: session.preset.cycleCount,
            phaseStartDate: session.completedAt ?? .now,
            phaseEndDate: session.completedAt ?? .now,
            phaseDuration: 0,
            elapsedSeconds: 0,
            remainingSeconds: 0,
            progress: 1,
            isPaused: false,
            nextPhase: nil,
            nextPhaseDuration: nil
        )
    }

    private func nextMeaningfulPhase(after index: Int, in segments: [SessionSegment]) -> SessionSegment? {
        segments
            .dropFirst(index + 1)
            .first(where: { $0.phase == .work || $0.phase == .rest })
    }

    private func requestAudioSync() {
        audioSyncTask?.cancel()

        let snapshot = snapshot
        let remainingSegments = remainingSegments()

        audioSyncTask = Task { @MainActor [weak self] in
            await Task.yield()

            guard let self, !Task.isCancelled else { return }

            guard let snapshot else {
                self.audioCoordinator.stop()
                return
            }

            if snapshot.phase == .completed {
                self.audioCoordinator.playCompletionCue()
                return
            }

            guard !snapshot.isPaused else {
                self.audioCoordinator.stop()
                return
            }

            self.audioCoordinator.play(snapshot: snapshot, remainingSegments: remainingSegments)
        }
    }
}
