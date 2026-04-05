import AVFoundation
import Foundation

protocol SessionAudioControlling: AnyObject {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment])
    func playCompletionCue()
    func stop()
}

final class SessionAudioCoordinator: SessionAudioControlling, @unchecked Sendable {
    private enum AudioError: Error {
        case missingResource(String)
    }

    private struct ScheduledCue {
        let id: UUID
        let fireDate: Date
        let url: URL
    }

    private static let halfwayPhrase = "Half way there"
    private static let tenSecondsPhrase = "10 seconds"
    private static let restPhrase = "Rest"
    private static let workoutCompletePhrase = "Workout complete"

    private let speechRenderer = SpeechClipRenderer()
    private let sampleRate: Double = 22_050
    private let lateCueTolerance: TimeInterval = 0.25
    private let queue = DispatchQueue(label: "com.tatabara.session-audio", qos: .userInitiated)

    private var engine = AVAudioEngine()
    private var ambienceNode = AVAudioPlayerNode()
    private var silentLoopBuffer: AVAudioPCMBuffer?
    private var voicePreparationTask: Task<Void, Never>?
    private var warmupTask: Task<Void, Never>?
    private var cleanupWorkItems: [UUID: DispatchWorkItem] = [:]
    private var activePlayers: [UUID: AVAudioPlayer] = [:]
    private var playbackGeneration: UInt = 0

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        let renderer = speechRenderer
        warmupTask = Task.detached {
            _ = try? await renderer.fileURL(for: Self.halfwayPhrase)
            _ = try? await renderer.fileURL(for: Self.tenSecondsPhrase)
            _ = try? await renderer.fileURL(for: Self.restPhrase)
            _ = try? await renderer.fileURL(for: Self.workoutCompletePhrase)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func play(
        snapshot: TimerSessionSnapshot,
        remainingSegments: [SessionSegment]
    ) {
        queue.async { [weak self] in
            self?.beginPlayback(snapshot: snapshot, remainingSegments: remainingSegments)
        }
    }

    func playCompletionCue() {
        queue.async { [weak self] in
            self?.beginCompletionPlayback()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.stopPlayback(incrementGeneration: true, deactivateSession: true)
        }
    }

    @objc
    private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let value = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: value)
        else {
            return
        }

        if interruptionType == .began {
            stop()
        }
    }

    private func beginPlayback(
        snapshot: TimerSessionSnapshot,
        remainingSegments: [SessionSegment]
    ) {
        playbackGeneration &+= 1
        let generation = playbackGeneration

        voicePreparationTask?.cancel()
        voicePreparationTask = nil
        cancelCleanupTasks()
        stopActivePlayers()

        guard snapshot.phase != .completed, !snapshot.isPaused else {
            stopPlayback(incrementGeneration: false, deactivateSession: true)
            return
        }

        let cues = SessionCuePlanner.cues(
            for: remainingSegments,
            currentElapsed: snapshot.elapsedSeconds
        )
        let snapshotMoment = snapshot.phaseStartDate.addingTimeInterval(snapshot.elapsedSeconds)

        do {
            try startPlayback()

            let bundledURLs = try preloadBundledURLs(for: cues)
            let beepSchedule = makeScheduledCues(
                from: cues.filter { !$0.kind.isVoice },
                snapshotMoment: snapshotMoment,
                urls: bundledURLs
            )
            scheduleCuePlayback(beepSchedule)
        } catch {
            stopPlayback(incrementGeneration: false, deactivateSession: true)
            return
        }

        let renderer = speechRenderer
        let warmupTask = warmupTask
        let audioQueue = queue
        voicePreparationTask = Task.detached { [weak self] in
            do {
                let voiceURLs = try await Self.preloadVoiceURLs(
                    for: cues,
                    speechRenderer: renderer,
                    warmupTask: warmupTask
                )
                guard !Task.isCancelled else { return }

                audioQueue.async { [weak self] in
                    guard let self, self.playbackGeneration == generation else { return }

                    let voiceSchedule = self.makeScheduledCues(
                        from: cues.filter { $0.kind.isVoice },
                        snapshotMoment: snapshotMoment,
                        urls: voiceURLs
                    )
                    self.scheduleCuePlayback(voiceSchedule)
                }
            } catch {
                // Keep the workout running even if spoken prompts fail to render.
            }
        }
    }

    private func beginCompletionPlayback() {
        playbackGeneration &+= 1
        let generation = playbackGeneration

        voicePreparationTask?.cancel()
        voicePreparationTask = nil
        cancelCleanupTasks()
        stopActivePlayers()

        do {
            try startPlayback()
        } catch {
            stopPlayback(incrementGeneration: false, deactivateSession: true)
            return
        }

        let renderer = speechRenderer
        let warmupTask = warmupTask
        let audioQueue = queue

        voicePreparationTask = Task.detached { [weak self] in
            do {
                await warmupTask?.value
                let url = try await renderer.fileURL(for: Self.workoutCompletePhrase)
                guard !Task.isCancelled else { return }

                audioQueue.async { [weak self] in
                    guard let self, self.playbackGeneration == generation else { return }
                    self.playImmediateCue(from: url)
                }
            } catch {
                audioQueue.async { [weak self] in
                    self?.stopPlayback(incrementGeneration: false, deactivateSession: true)
                }
            }
        }
    }

    private func stopPlayback(incrementGeneration: Bool, deactivateSession: Bool) {
        if incrementGeneration {
            playbackGeneration &+= 1
        }

        voicePreparationTask?.cancel()
        voicePreparationTask = nil
        cancelCleanupTasks()
        stopActivePlayers()
        ambienceNode.stop()
        engine.stop()
        engine.reset()
        silentLoopBuffer = nil

        if deactivateSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    private func startPlayback() throws {
        stopActivePlayers()
        ambienceNode.stop()
        engine.stop()
        engine.reset()

        try configureAudioSession()
        setupEngineGraph()
        try engine.start()

        // Keep the playback session alive with a tiny looping silent buffer instead of
        // generating a full workout-length silent audio file on the main actor.
        let silentLoopBuffer = Self.makeSilentLoopBuffer(sampleRate: sampleRate)
        self.silentLoopBuffer = silentLoopBuffer
        ambienceNode.scheduleBuffer(
            silentLoopBuffer,
            at: AVAudioTime(sampleTime: 0, atRate: sampleRate),
            options: [.loops],
            completionHandler: nil
        )

        ambienceNode.volume = 0.001
        ambienceNode.play()
    }

    private func setupEngineGraph() {
        engine = AVAudioEngine()
        ambienceNode = AVAudioPlayerNode()

        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        engine.attach(ambienceNode)
        engine.connect(ambienceNode, to: engine.mainMixerNode, format: outputFormat)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try session.setActive(true)
    }

    private func preloadBundledURLs(for cues: [SessionCue]) throws -> [SessionCueKind: URL] {
        let kinds = Set(cues.map(\.kind).filter { !$0.isVoice })
        var urls: [SessionCueKind: URL] = [:]

        for kind in kinds {
            switch kind {
            case .beepShort:
                urls[kind] = try bundledAudio(named: "beep-short")
            case .beepLong:
                urls[kind] = try bundledAudio(named: "beep-long")
            case .beepRestFinal:
                urls[kind] = try bundledAudio(named: "beep-rest-final")
            case .voiceRound(_), .voiceRest, .voiceHalfway, .voiceTenSeconds:
                continue
            }
        }

        return urls
    }

    private static func preloadVoiceURLs(
        for cues: [SessionCue],
        speechRenderer: SpeechClipRenderer,
        warmupTask: Task<Void, Never>?
    ) async throws -> [SessionCueKind: URL] {
        let kinds = Set(cues.map(\.kind).filter { $0.isVoice })
        guard !kinds.isEmpty else { return [:] }

        await warmupTask?.value

        var urls: [SessionCueKind: URL] = [:]

        for kind in kinds {
            switch kind {
            case .voiceRound(_), .voiceRest, .voiceHalfway, .voiceTenSeconds:
                urls[kind] = try await speechRenderer.fileURL(for: phrase(for: kind))
            case .beepShort, .beepLong, .beepRestFinal:
                continue
            }
        }

        return urls
    }

    private func makeScheduledCues(
        from cues: [SessionCue],
        snapshotMoment: Date,
        urls: [SessionCueKind: URL]
    ) -> [ScheduledCue] {
        cues.compactMap { cue in
            guard let url = urls[cue.kind] else { return nil }

            return ScheduledCue(
                id: cue.id,
                fireDate: snapshotMoment.addingTimeInterval(cue.offsetSeconds),
                url: url
            )
        }
        .sorted { $0.fireDate < $1.fireDate }
    }

    private func scheduleCuePlayback(_ scheduledCues: [ScheduledCue]) {
        for scheduledCue in scheduledCues {
            let delay = scheduledCue.fireDate.timeIntervalSinceNow

            if delay < -lateCueTolerance {
                continue
            }

            do {
                let player = try AVAudioPlayer(contentsOf: scheduledCue.url)
                player.volume = 1.0
                player.prepareToPlay()

                let playerID = scheduledCue.id
                activePlayers[playerID] = player

                let didStart: Bool
                if delay <= 0 {
                    didStart = player.play()
                } else {
                    didStart = player.play(atTime: player.deviceCurrentTime + delay)
                }

                guard didStart else {
                    activePlayers[playerID] = nil
                    continue
                }

                let cleanupDelay = max(delay, 0) + max(player.duration, 0.2) + 0.5
                let cleanupWorkItem = DispatchWorkItem { [weak self] in
                    self?.releasePlayer(playerID)
                }
                cleanupWorkItems[playerID] = cleanupWorkItem
                queue.asyncAfter(deadline: .now() + cleanupDelay, execute: cleanupWorkItem)
            } catch {
                continue
            }
        }
    }

    private func playImmediateCue(from url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()

            let playerID = UUID()
            activePlayers[playerID] = player

            guard player.play() else {
                activePlayers[playerID] = nil
                stopPlayback(incrementGeneration: false, deactivateSession: true)
                return
            }

            let cleanupDelay = max(player.duration, 0.2) + 0.5
            let cleanupWorkItem = DispatchWorkItem { [weak self] in
                self?.releasePlayer(playerID)
                self?.stopPlayback(incrementGeneration: false, deactivateSession: true)
            }
            cleanupWorkItems[playerID] = cleanupWorkItem
            queue.asyncAfter(deadline: .now() + cleanupDelay, execute: cleanupWorkItem)
        } catch {
            stopPlayback(incrementGeneration: false, deactivateSession: true)
        }
    }

    private func cancelCleanupTasks() {
        cleanupWorkItems.values.forEach { $0.cancel() }
        cleanupWorkItems.removeAll()
    }

    private func releasePlayer(_ id: UUID) {
        activePlayers[id] = nil
        cleanupWorkItems[id] = nil
    }

    private func stopActivePlayers() {
        activePlayers.values.forEach { $0.stop() }
        activePlayers.removeAll()
    }

    private func bundledAudio(named name: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            throw AudioError.missingResource(name)
        }

        return url
    }

    private static func phrase(for kind: SessionCueKind) -> String {
        switch kind {
        case let .voiceRound(round):
            "Round \(round)"
        case .voiceRest:
            restPhrase
        case .voiceHalfway:
            halfwayPhrase
        case .voiceTenSeconds:
            tenSecondsPhrase
        case .beepShort, .beepLong, .beepRestFinal:
            preconditionFailure("Requested a voice phrase for a non-voice cue.")
        }
    }

    private static func makeSilentLoopBuffer(
        sampleRate: Double
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        if let channelData = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                channelData[channel].initialize(repeating: 0, count: Int(frameCount))
            }
        }

        return buffer
    }
}

final class NoopSessionAudioCoordinator: SessionAudioControlling {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {}
    func playCompletionCue() {}
    func stop() {}
}
