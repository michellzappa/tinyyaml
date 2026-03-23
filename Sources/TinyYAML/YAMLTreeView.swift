import SwiftUI
import AppKit
import Yams

/// A node in the parsed YAML tree.
final class YAMLNode: NSObject {
    enum Kind {
        case mapping([(key: String, value: YAMLNode)])
        case sequence([YAMLNode])
        case scalar(String)
    }

    let kind: Kind
    let label: String

    init(kind: Kind, label: String = "") {
        self.kind = kind
        self.label = label
    }

    var isExpandable: Bool {
        switch kind {
        case .mapping(let pairs): return !pairs.isEmpty
        case .sequence(let items): return !items.isEmpty
        default: return false
        }
    }

    var childCount: Int {
        switch kind {
        case .mapping(let pairs): return pairs.count
        case .sequence(let items): return items.count
        default: return 0
        }
    }

    func child(at index: Int) -> YAMLNode {
        switch kind {
        case .mapping(let pairs): return pairs[index].value
        case .sequence(let items): return items[index]
        default: fatalError("No children")
        }
    }

    var displayValue: String {
        switch kind {
        case .mapping(let pairs): return "{\(pairs.count) \(pairs.count == 1 ? "key" : "keys")}"
        case .sequence(let items): return "[\(items.count) \(items.count == 1 ? "item" : "items")]"
        case .scalar(let s): return s
        }
    }

    /// Classify a scalar value for color coding.
    enum ScalarType {
        case string, number, boolean, null
    }

    var scalarType: ScalarType {
        guard case .scalar(let s) = kind else { return .string }
        let lower = s.lowercased()
        if lower == "null" || lower == "~" || s.isEmpty { return .null }
        if lower == "true" || lower == "false" || lower == "yes" || lower == "no" { return .boolean }
        if Double(s) != nil || Int(s) != nil { return .number }
        return .string
    }

    /// Build a YAMLNode tree from a Yams Node.
    static func from(_ node: Yams.Node, label: String = "root") -> YAMLNode {
        switch node {
        case .mapping(let mapping):
            let pairs: [(key: String, value: YAMLNode)] = mapping.map { pair in
                let key = pair.key.scalar?.string ?? "?"
                return (key: key, value: from(pair.value, label: key))
            }
            return YAMLNode(kind: .mapping(pairs), label: label)
        case .sequence(let sequence):
            let items = sequence.enumerated().map { from($0.element, label: "[\($0.offset)]") }
            return YAMLNode(kind: .sequence(items), label: label)
        case .scalar(let scalar):
            return YAMLNode(kind: .scalar(scalar.string), label: label)
        @unknown default:
            return YAMLNode(kind: .scalar("?"), label: label)
        }
    }
}

/// Renders a YAML tree as a collapsible NSOutlineView.
struct YAMLTreeView: NSViewRepresentable {
    let rootNode: YAMLNode?
    let expandAll: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let outlineView = NSOutlineView()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("yaml"))
        column.title = "YAML"
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.usesAlternatingRowBackgroundColors = true
        outlineView.rowHeight = 22
        outlineView.indentationPerLevel = 18
        outlineView.autoresizesOutlineColumn = true

        outlineView.delegate = context.coordinator
        outlineView.dataSource = context.coordinator

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        context.coordinator.outlineView = outlineView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        let rootChanged = coordinator.rootNode !== rootNode
        coordinator.rootNode = rootNode
        coordinator.expandAllFlag = expandAll

        if rootChanged {
            coordinator.outlineView?.reloadData()
        }

        if let outlineView = coordinator.outlineView, rootNode != nil {
            if expandAll {
                outlineView.expandItem(nil, expandChildren: true)
            } else {
                outlineView.collapseItem(nil, collapseChildren: true)
                if let root = rootNode {
                    outlineView.expandItem(root)
                }
            }
        }
    }

    final class Coordinator: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {
        var outlineView: NSOutlineView?
        var rootNode: YAMLNode?
        var expandAllFlag = true

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            if item == nil { return rootNode != nil ? 1 : 0 }
            guard let node = item as? YAMLNode else { return 0 }
            return node.childCount
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if item == nil { return rootNode! }
            guard let node = item as? YAMLNode else { fatalError() }
            return node.child(at: index)
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? YAMLNode else { return false }
            return node.isExpandable
        }

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? YAMLNode else { return nil }

            let cellID = NSUserInterfaceItemIdentifier("yamlCell")
            let cell: NSTextField
            if let existing = outlineView.makeView(withIdentifier: cellID, owner: nil) as? NSTextField {
                cell = existing
            } else {
                cell = NSTextField(labelWithString: "")
                cell.identifier = cellID
                cell.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
                cell.lineBreakMode = .byTruncatingTail
                cell.cell?.truncatesLastVisibleLine = true
            }

            let attributed = NSMutableAttributedString()
            let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            let boldFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            // Key label
            if !node.label.isEmpty && node.label != "root" {
                let keyColor: NSColor = isDark
                    ? NSColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1.0)
                    : NSColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
                attributed.append(NSAttributedString(string: node.label, attributes: [
                    .font: boldFont,
                    .foregroundColor: keyColor,
                ]))
                attributed.append(NSAttributedString(string: ": ", attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.secondaryLabelColor,
                ]))
            }

            // Value
            let valueStr: String
            let valueColor: NSColor

            switch node.kind {
            case .mapping, .sequence:
                valueStr = node.displayValue
                valueColor = NSColor.secondaryLabelColor
            case .scalar:
                valueStr = node.displayValue
                switch node.scalarType {
                case .string:
                    valueColor = isDark
                        ? NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1.0)
                        : NSColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
                case .number:
                    valueColor = isDark
                        ? NSColor(red: 0.95, green: 0.7, blue: 0.4, alpha: 1.0)
                        : NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
                case .boolean:
                    valueColor = isDark
                        ? NSColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
                        : NSColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1.0)
                case .null:
                    valueColor = isDark
                        ? NSColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
                        : NSColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1.0)
                }
            }

            attributed.append(NSAttributedString(string: valueStr, attributes: [
                .font: baseFont,
                .foregroundColor: valueColor,
            ]))

            cell.attributedStringValue = attributed
            cell.toolTip = "\(node.label): \(valueStr)"

            return cell
        }
    }
}
