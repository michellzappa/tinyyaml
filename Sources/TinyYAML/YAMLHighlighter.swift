import AppKit
import TinyKit

/// Syntax highlighter for YAML files.
/// Colors keys, values, comments, document markers, and anchors/aliases.
final class YAMLHighlighter: SyntaxHighlighting {
    var baseFont: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    private var isDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private var keyColor: NSColor {
        isDark ? NSColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1.0)
               : NSColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
    }

    private var stringColor: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1.0)
               : NSColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
    }

    private var numberColor: NSColor {
        isDark ? NSColor(red: 0.95, green: 0.7, blue: 0.4, alpha: 1.0)
               : NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
    }

    private var boolNullColor: NSColor {
        isDark ? NSColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
               : NSColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1.0)
    }

    private var commentColor: NSColor {
        isDark ? NSColor(red: 0.5, green: 0.55, blue: 0.5, alpha: 1.0)
               : NSColor(red: 0.4, green: 0.45, blue: 0.4, alpha: 1.0)
    }

    private var anchorColor: NSColor {
        isDark ? NSColor(red: 0.5, green: 0.8, blue: 0.8, alpha: 1.0)
               : NSColor(red: 0.2, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    private var documentMarkerColor: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
               : NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    }

    // Precompiled patterns
    private static let commentRegex = try! NSRegularExpression(pattern: #"#.*$"#, options: .anchorsMatchLines)
    private static let keyRegex = try! NSRegularExpression(pattern: #"^(\s*-?\s*)([^\s#:][^:#]*?)(\s*:)(?=\s|$)"#, options: .anchorsMatchLines)
    private static let quotedStringRegex = try! NSRegularExpression(pattern: #"(?:\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*')"#)
    private static let boolRegex = try! NSRegularExpression(pattern: #"\b(true|false|yes|no|True|False|Yes|No|TRUE|FALSE|YES|NO)\b"#)
    private static let nullRegex = try! NSRegularExpression(pattern: #"\b(null|Null|NULL|~)\b"#)
    private static let numberRegex = try! NSRegularExpression(pattern: #"(?<=:\s)\s*-?(?:0x[0-9a-fA-F]+|0o[0-7]+|0b[01]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|\.inf|\.nan)\s*$"#, options: .anchorsMatchLines)
    private static let anchorRegex = try! NSRegularExpression(pattern: #"[&*][a-zA-Z_][a-zA-Z0-9_]*"#)
    private static let documentMarkerRegex = try! NSRegularExpression(pattern: #"^(?:---|\.\.\.)\s*$"#, options: .anchorsMatchLines)

    func highlight(_ textStorage: NSTextStorage) {
        let source = textStorage.string
        let fullRange = NSRange(location: 0, length: (source as NSString).length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Reset to base
        textStorage.addAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.clear,
        ], range: fullRange)

        let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .medium)
        let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)

        // Document markers (--- / ...)
        for match in Self.documentMarkerRegex.matches(in: source, range: fullRange) {
            textStorage.addAttributes([
                .foregroundColor: documentMarkerColor,
                .font: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold),
            ], range: match.range)
        }

        // Keys (before colon)
        for match in Self.keyRegex.matches(in: source, range: fullRange) {
            if match.numberOfRanges >= 3 {
                let keyRange = match.range(at: 2)
                textStorage.addAttributes([
                    .foregroundColor: keyColor,
                    .font: boldFont,
                ], range: keyRange)
            }
        }

        // Quoted strings
        for match in Self.quotedStringRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: stringColor, range: match.range)
        }

        // Booleans
        for match in Self.boolRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: boolNullColor, range: match.range)
        }

        // Null
        for match in Self.nullRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: boolNullColor, range: match.range)
        }

        // Numbers (after colon)
        for match in Self.numberRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: numberColor, range: match.range)
        }

        // Anchors & aliases
        for match in Self.anchorRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: anchorColor, range: match.range)
        }

        // Comments (applied last to override other colors)
        for match in Self.commentRegex.matches(in: source, range: fullRange) {
            textStorage.addAttributes([
                .foregroundColor: commentColor,
                .font: italicFont,
            ], range: match.range)
        }

        textStorage.endEditing()
    }
}
