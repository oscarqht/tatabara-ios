import Foundation

enum SessionCueKind: Equatable, Hashable {
    case beepShort
    case beepLong
    case beepRestFinal
    case voiceHalfway
    case voiceTenSeconds

    var isVoice: Bool {
        switch self {
        case .voiceHalfway, .voiceTenSeconds:
            true
        case .beepShort, .beepLong, .beepRestFinal:
            false
        }
    }
}

struct SessionCue: Equatable, Hashable, Identifiable {
    let id = UUID()
    let offsetSeconds: TimeInterval
    let kind: SessionCueKind
}
