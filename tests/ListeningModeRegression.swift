import Foundation
import CoreFoundation

enum AirPodsListeningMode: Equatable {
    case noiseCancellation
    case transparency
    case adaptive
    case conversationAwareness
    case off

    var displayName: String {
        switch self {
        case .noiseCancellation:
            return String(localized: "Noise Cancellation")
        case .transparency:
            return String(localized: "Transparency")
        case .adaptive:
            return String(localized: "Adaptive Audio")
        case .conversationAwareness:
            return String(localized: "Conversation Awareness")
        case .off:
            return String(localized: "Off")
        }
    }

    var sfSymbol: String {
        switch self {
        case .noiseCancellation:
            return "ear.badge.waveform"
        case .transparency:
            return "ear"
        case .adaptive:
            return "waveform"
        case .conversationAwareness:
            return "person.wave.2"
        case .off:
            return "airpods.pro"
        }
    }

    static func fromHUDSymbol(_ symbol: String) -> AirPodsListeningMode? {
        switch symbol {
        case "ear.badge.waveform", "airpods.mode.noise-cancellation":
            return .noiseCancellation
        case "ear", "airpods.mode.transparency":
            return .transparency
        case "waveform", "airpods.mode.adaptive":
            return .adaptive
        case "person.wave.2", "airpods.mode.conversation-awareness":
            return .conversationAwareness
        case "airpods.pro", "airpods.mode.off":
            return .off
        default:
            return nil
        }
    }

    static func from(userInfo: [AnyHashable: Any]?) -> AirPodsListeningMode? {
        guard let userInfo else { return nil }

        // Feature flags (adaptive audio/conversation awareness) are independent of ANC.
        let modeKeys = ["listeningMode", "ListeningMode", "LsnM", "noiseControlMode",
                        "NoiseControlMode", "activeNoiseControlMode", "activeNoiseCancellationMode",
                        "ANCMode", "ancMode"]

        for key in modeKeys {
            if let value = userInfo[key], let mode = from(value) {
                return mode
            }
        }

        return nil
    }

    static func from(_ value: Any) -> AirPodsListeningMode? {
        if let mode = value as? AirPodsListeningMode {
            return mode
        }

        if let number = value as? NSNumber {
            guard CFGetTypeID(number) != CFBooleanGetTypeID(),
                  number.doubleValue == Double(number.intValue) else { return nil }
            return fromPrivateValue(number.intValue)
        }

        if let string = value as? String {
            return from(string)
        }

        return from("\(value)")
    }

    static func fromPrivateValue(_ value: Int) -> AirPodsListeningMode? {
        switch value {
        case 0:
            return .off
        case 1:
            return .noiseCancellation
        case 2:
            return .transparency
        case 3:
            return .adaptive
        case 4:
            return .conversationAwareness
        default:
            return nil
        }
    }

    private static func from(_ rawValue: String) -> AirPodsListeningMode? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        func exact(_ token: String) -> AirPodsListeningMode? {
            switch token {
            case "0", "off", "normal": return .off
            case "1", "anc", "noisecancellation", "noise cancellation", "noise cancelling", "noisecancelling": return .noiseCancellation
            case "2", "transparency", "transparent", "ambient": return .transparency
            case "3", "autoanc", "adaptive", "adaptive audio": return .adaptive
            case "4", "conversation awareness": return .conversationAwareness
            default: return nil
            }
        }
        if let mode = exact(value) { return mode }
        // Parse a current-value field, never a substring of a property name or device name.
        // For transition logs use the destination rather than the old mode.
        let pattern = #"\b(?:lsnm|listeningmode|noisecontrolmode|activenoisecontrolmode|activenoisecancellationmode|ancmode)\b[\s"']*[:=]?\s*["']?(autoanc|anc|normal|off|transparency|adaptive|noise cancellation|noisecancellation|noise cancelling|[0-4])\b(?:\s*(?:->|=>)\s*(autoanc|anc|normal|off|transparency|adaptive|noise cancellation|noisecancellation|noise cancelling|[0-4])\b)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.matches(in: value, range: NSRange(value.startIndex..., in: value)).last else { return nil }
        let group = match.range(at: 2).location == NSNotFound ? 1 : 2
        guard let range = Range(match.range(at: group), in: value) else { return nil }
        return exact(String(value[range]))
    }

}

let cases: [(Any, AirPodsListeningMode?)] = [
    ("noiseControlMode=0", .off), ("noiseControlMode=1", .noiseCancellation),
    ("LsnM ANC -> Normal", .off), ("LsnM Normal -> ANC", .noiseCancellation),
    ("LsnM AutoANC", .adaptive), ("activeNoiseCancellationMode = 0", .off),
    ("Fancy headphones", nil), ("noiseControlMode=10", nil),
    ("adaptiveAudioMode=0", nil), ("conversationAwareness=1", nil),
    (NSNumber(value: true), nil), (NSNumber(value: 1.5), nil),
    (NSNumber(value: 1), .noiseCancellation), (NSNumber(value: 0), .off)
]
for (value, expected) in cases {
    precondition(AirPodsListeningMode.from(value) == expected, "Unexpected mode: \(value)")
}
precondition(AirPodsListeningMode.from(userInfo: ["adaptiveAudioMode": 0]) == nil)
precondition(AirPodsListeningMode.from(userInfo: ["conversationAwareness": true]) == nil)
precondition(AirPodsListeningMode.from(userInfo: ["noiseControlMode": 0]) == .off)
print("Passed listening-mode regression cases")
