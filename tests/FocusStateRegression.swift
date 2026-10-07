import Foundation

enum FocusStateRegression {
    static func extractActiveState(from description: String) -> Bool? {
        if description.contains("active mode assertion: (null)") || description.contains("activeModeIdentifier: (null)") {
            return false
        }
        guard description.contains("semanticModeIdentifier"),
              let range = description.range(of: #"\bstarting:\s*[01]\b"#, options: .regularExpression) else { return nil }
        return description[range].trimmingCharacters(in: .whitespaces).hasSuffix("1")
    }

}
let cases: [(String, Bool?)] = [
    ("semanticModeIdentifier: com.apple.donotdisturb.mode starting: 1", true),
    ("semanticModeIdentifier: com.apple.focus.work starting: 0", false),
    ("semanticModeIdentifier: com.apple.focus.sleep starting:    1", true),
    ("active mode assertion: (null)", false),
    ("activeModeIdentifier: (null)", false),
    ("semanticModeIdentifier: com.apple.focus.work", nil),
    ("unrelated starting: 1", nil),
    ("semanticModeIdentifier starting: 10", nil),
    ("log stream terminated", nil)
]
for (line, expected) in cases {
    precondition(FocusStateRegression.extractActiveState(from: line) == expected, line)
}
print("Passed \(cases.count) Focus state parsing cases")
