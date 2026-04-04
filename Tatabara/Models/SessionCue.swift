import Foundation

enum SessionCueKind: Equatable, Hashable {
    case beepShort
    case beepLong
    case beepRestFinal
    case voiceHalfway
    case voiceTenSeconds
}

struct SessionCue: Equatable, Hashable, Identifiable {
    let id = UUID()
    let offsetSeconds: TimeInterval
    let kind: SessionCueKind
}
