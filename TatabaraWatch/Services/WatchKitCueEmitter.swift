import Foundation
import WatchKit

final class WatchKitCueEmitter: WatchCueEmitting, @unchecked Sendable {
    func emit(_ pattern: WatchCuePattern) {
        let haptic: WKHapticType

        switch pattern {
        case .phaseStart:
            haptic = .start
        case .countdownTick:
            haptic = .click
        case .countdownFinal:
            haptic = .directionUp
        case .completion:
            haptic = .success
        }

        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(haptic)
        }
    }
}
