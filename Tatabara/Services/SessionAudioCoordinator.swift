import AVFoundation
import Foundation

@MainActor
protocol SessionAudioControlling: AnyObject {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment])
    func stop()
}

@MainActor
final class SessionAudioCoordinator: SessionAudioControlling {
    private enum AudioError: Error {
        case missingResource(String)
    }

    private let speechRenderer = SpeechClipRenderer()
    private let sampleRate: Double = 22_050

    private var engine = AVAudioEngine()
    private var ambienceNode = AVAudioPlayerNode()
    private var cueNode = AVAudioPlayerNode()
    private var renderTask: Task<Void, Never>?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func play(
        snapshot: TimerSessionSnapshot,
        remainingSegments: [SessionSegment]
    ) {
        renderTask?.cancel()

        guard snapshot.phase != .completed, !snapshot.isPaused else {
            stop()
            return
        }

        renderTask = Task { [weak self] in
            guard let self else { return }

            do {
                let cues = SessionCuePlanner.cues(
                    for: remainingSegments,
                    currentElapsed: snapshot.elapsedSeconds
                )
                let remainingDuration = SessionCuePlanner.remainingDuration(
                    for: remainingSegments,
                    currentElapsed: snapshot.elapsedSeconds
                )
                try await self.startPlayback(cues: cues, remainingDuration: remainingDuration)
            } catch {
                await MainActor.run {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        renderTask?.cancel()
        ambienceNode.stop()
        cueNode.stop()
        engine.stop()
        engine.reset()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
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

    private func startPlayback(cues: [SessionCue], remainingDuration: TimeInterval) async throws {
        stop()

        let silentBedURL = try Self.makeSilentBed(duration: max(remainingDuration, 1), sampleRate: sampleRate)
        let clipURLs = try await clipURLs(for: cues)
        try configureAudioSession()
        setupEngineGraph()
        try engine.start()

        let ambienceFile = try AVAudioFile(forReading: silentBedURL)
        ambienceNode.scheduleFile(
            ambienceFile,
            at: AVAudioTime(sampleTime: 0, atRate: sampleRate),
            completionHandler: nil
        )

        for cue in cues {
            guard let cueURL = clipURLs[cue.kind] else { continue }
            let cueFile = try AVAudioFile(forReading: cueURL)
            let sampleTime = AVAudioFramePosition(cue.offsetSeconds * sampleRate)
            cueNode.scheduleFile(
                cueFile,
                at: AVAudioTime(sampleTime: sampleTime, atRate: sampleRate),
                completionHandler: nil
            )
        }

        ambienceNode.volume = 0.001
        cueNode.volume = 1.0
        ambienceNode.play()
        cueNode.play()
    }

    private func setupEngineGraph() {
        engine = AVAudioEngine()
        ambienceNode = AVAudioPlayerNode()
        cueNode = AVAudioPlayerNode()

        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        engine.attach(ambienceNode)
        engine.attach(cueNode)
        engine.connect(ambienceNode, to: engine.mainMixerNode, format: outputFormat)
        engine.connect(cueNode, to: engine.mainMixerNode, format: nil)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try session.setActive(true)
    }

    private func clipURLs(for cues: [SessionCue]) async throws -> [SessionCueKind: URL] {
        let kinds = Set(cues.map(\.kind))
        var urls: [SessionCueKind: URL] = [:]

        for kind in kinds {
            switch kind {
            case .beepShort:
                urls[kind] = try bundledAudio(named: "beep-short")
            case .beepLong:
                urls[kind] = try bundledAudio(named: "beep-long")
            case .beepRestFinal:
                urls[kind] = try bundledAudio(named: "beep-rest-final")
            case .voiceHalfway:
                urls[kind] = try await speechRenderer.fileURL(for: "Half way there")
            case .voiceTenSeconds:
                urls[kind] = try await speechRenderer.fileURL(for: "10 seconds")
            }
        }

        return urls
    }

    private func bundledAudio(named name: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            throw AudioError.missingResource(name)
        }

        return url
    }

    private static func makeSilentBed(
        duration: TimeInterval,
        sampleRate: Double
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tatabara-silent-\(Int(duration.rounded(.up)))")
            .appendingPathExtension("caf")

        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)

        let totalFrames = AVAudioFrameCount(duration * sampleRate)
        let chunkFrames: AVAudioFrameCount = 4096
        var writtenFrames: AVAudioFrameCount = 0

        while writtenFrames < totalFrames {
            let nextChunk = min(chunkFrames, totalFrames - writtenFrames)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: nextChunk) else {
                break
            }

            buffer.frameLength = nextChunk
            try file.write(from: buffer)
            writtenFrames += nextChunk
        }

        return url
    }
}

@MainActor
final class NoopSessionAudioCoordinator: SessionAudioControlling {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {}
    func stop() {}
}
