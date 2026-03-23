import Foundation
import AppKit
import TinyKit
import Yams

@Observable
final class AppState: FileState {
    init() {
        super.init(
            bookmarkKey: "lastFolderBookmarkYAML",
            defaultExtension: "yaml",
            supportedExtensions: ["yaml", "yml", "toml"]
        )
    }

    var isYAMLFile: Bool {
        guard let ext = selectedFile?.pathExtension.lowercased() else { return false }
        return ["yaml", "yml"].contains(ext)
    }

    // MARK: - Parsing (computed — re-parses on each access like TinyJSON)

    var parsedYAML: Yams.Node? {
        guard isYAMLFile, !content.isEmpty else { return nil }
        return try? Yams.compose(yaml: content)
    }

    var yamlError: String? {
        guard isYAMLFile, !content.isEmpty else { return nil }
        do {
            _ = try Yams.compose(yaml: content)
            return nil
        } catch let error as YamlError {
            return friendlyError(from: error)
        } catch {
            return error.localizedDescription
        }
    }

    var errorLine: Int? {
        guard isYAMLFile, !content.isEmpty else { return nil }
        do {
            _ = try Yams.compose(yaml: content)
            return nil
        } catch let error as YamlError {
            return extractLine(from: error)
        } catch {
            return nil
        }
    }

    var errorOffset: Int? {
        guard let line = errorLine else { return nil }
        let lines = content.components(separatedBy: "\n")
        var offset = 0
        for i in 0..<min(line, lines.count) {
            offset += (lines[i] as NSString).length + 1
        }
        return offset
    }

    private func friendlyError(from error: YamlError) -> String {
        switch error {
        case .scanner(let context, let problem, let mark, _):
            var msg = problem
            if let ctx = context {
                msg += " (\(ctx.description))"
            }
            msg += " at line \(mark.line + 1), column \(mark.column + 1)"
            return msg
        case .parser(let context, let problem, let mark, _):
            var msg = problem
            if let ctx = context {
                msg += " (\(ctx.description))"
            }
            msg += " at line \(mark.line + 1), column \(mark.column + 1)"
            return msg
        default:
            return error.localizedDescription
        }
    }

    private func extractLine(from error: YamlError) -> Int? {
        switch error {
        case .scanner(_, _, let mark, _), .parser(_, _, let mark, _):
            return mark.line
        default:
            return nil
        }
    }

    // MARK: - Spotlight

    private static let spotlightDomain = "com.tinyapps.tinyyaml.files"

    override func didOpenFile(_ url: URL) {
        SpotlightIndexer.index(file: url, content: content, domainID: Self.spotlightDomain)
    }

    override func didSaveFile(_ url: URL) {
        didOpenFile(url)
    }
}
