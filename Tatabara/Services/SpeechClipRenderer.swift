import AVFoundation
import Foundation

actor SpeechClipRenderer {
    private var cachedFiles: [String: URL] = [:]

    func fileURL(for phrase: String) async throws -> URL {
        if let cached = cachedFiles[phrase] {
            return cached
        }

        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.autoupdatingCurrent.identifier)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.prefersAssistiveTechnologySettings = true

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tatabara-\(phrase.replacingOccurrences(of: " ", with: "-").lowercased())")
            .appendingPathExtension("caf")

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            cachedFiles[phrase] = destinationURL
            return destinationURL
        }

        var audioFile: AVAudioFile?
        var finished = false

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            synthesizer.write(utterance) { buffer in
                if finished {
                    return
                }

                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    finished = true
                    continuation.resume(returning: ())
                    return
                }

                if pcmBuffer.frameLength == 0 {
                    finished = true
                    continuation.resume(returning: ())
                    return
                }

                do {
                    if audioFile == nil {
                        audioFile = try AVAudioFile(
                            forWriting: destinationURL,
                            settings: pcmBuffer.format.settings
                        )
                    }

                    try audioFile?.write(from: pcmBuffer)
                } catch {
                    finished = true
                    continuation.resume(throwing: error)
                }
            }
        }

        cachedFiles[phrase] = destinationURL
        return destinationURL
    }
}
