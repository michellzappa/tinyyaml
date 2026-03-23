import SwiftUI
import TinyKit

struct ContentView: View {
    @Bindable var state: AppState
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @AppStorage("wordWrap") private var wordWrap = false
    @AppStorage("previewUserPref") private var previewUserPref = true
    @AppStorage("fontSize") private var fontSize: Double = 13
    @AppStorage("showLineNumbers") private var showLineNumbers = false
    @State private var showQuickOpen = false
    @State private var eventMonitor: Any?
    @State private var jumpToRange: NSRange?
    @State private var treeExpanded = true
    @State private var aiState = AIState()
    @State private var editorBridge = EditorBridge()

    private var showPreview: Bool {
        previewUserPref && state.isYAMLFile
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TinyFileList(state: state)
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 300)
        } detail: {
            VStack(spacing: 0) {
                if state.tabs.count > 1 {
                    TinyTabBar(state: state)
                    Divider()
                }
                if showPreview {
                    EditorSplitView {
                        TinyEditorView(
                            text: $state.content,
                            wordWrap: $wordWrap,
                            fontSize: $fontSize,
                            showLineNumbers: $showLineNumbers,
                            shouldHighlight: state.isYAMLFile,
                            highlighterProvider: { YAMLHighlighter() },
                            commentStyle: .hash,
                            jumpToRange: $jumpToRange,
                            editorBridge: editorBridge
                        )
                    } right: {
                        VStack(spacing: 0) {
                            // Error banner
                            if let error = state.yamlError {
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                        .padding(.top, 1)
                                    Text(error)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .lineLimit(4)
                                        .textSelection(.enabled)
                                    Spacer()
                                    if state.errorOffset != nil {
                                        Image(systemName: "arrow.right.circle")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(.red.opacity(0.08))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let offset = state.errorOffset {
                                        jumpToRange = NSRange(location: offset, length: 0)
                                    }
                                }
                                .help("Click to jump to error")
                                Divider()
                            }

                            // Tree controls
                            HStack(spacing: 8) {
                                Text("Tree")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)

                                Button {
                                    treeExpanded = true
                                } label: {
                                    Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                                .disabled(treeExpanded)
                                Button {
                                    treeExpanded = false
                                } label: {
                                    Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                                .disabled(!treeExpanded)

                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            Divider()

                            // Tree content
                            if let parsed = state.parsedYAML {
                                YAMLTreeView(rootNode: YAMLNode.from(parsed), expandAll: treeExpanded)
                            } else if state.yamlError != nil {
                                ContentUnavailableView("Invalid YAML", systemImage: "exclamationmark.triangle", description: Text("Fix the errors to see the tree preview"))
                            } else {
                                ContentUnavailableView("No YAML", systemImage: "doc.text", description: Text("Open a YAML file to see the tree preview"))
                            }
                        }
                    }
                } else {
                    TinyEditorView(
                        text: $state.content,
                        wordWrap: $wordWrap,
                        fontSize: $fontSize,
                        showLineNumbers: $showLineNumbers,
                        shouldHighlight: state.isYAMLFile,
                        highlighterProvider: { YAMLHighlighter() },
                        commentStyle: .hash,
                        jumpToRange: $jumpToRange,
                        editorBridge: editorBridge
                    )
                }

                StatusBarView(text: state.content)
            }
            .modifier(CmdKOverlay(aiState: aiState, editorBridge: editorBridge, content: state.content, fileExtension: state.selectedFile?.pathExtension ?? "yaml"))
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let chars = event.charactersIgnoringModifiers ?? ""

                if flags == .option && chars == "z" {
                    wordWrap.toggle()
                    return nil
                }
                if flags == .option && chars == "p" {
                    previewUserPref.toggle()
                    return nil
                }
                if flags == .option && chars == "l" {
                    showLineNumbers.toggle()
                    return nil
                }
                if flags == .command && chars == "p" {
                    showQuickOpen.toggle()
                    return nil
                }
                if flags == .command && chars == "w" && state.tabs.count > 1 {
                    state.closeActiveTab()
                    return nil
                }
                if flags == .command && chars == "k" {
                    aiState.activate(selection: editorBridge.currentSelection, range: editorBridge.currentSelectedRange, bridge: editorBridge, folderURL: state.folderURL, supportedExtensions: state.supportedExtensions)
                    return nil
                }
                if flags == .command && (chars == "=" || chars == "+") {
                    fontSize = min(fontSize + 1, 32)
                    return nil
                }
                if flags == .command && chars == "-" {
                    fontSize = max(fontSize - 1, 9)
                    return nil
                }
                if flags == .command && chars == "0" {
                    fontSize = 13
                    return nil
                }
                if flags == .command && (chars == "f" || chars == "g") {
                    return event
                }
                if flags == [.command, .shift] && chars == "g" {
                    return event
                }
                return event
            }
        }
        .sheet(isPresented: $showQuickOpen) {
            QuickOpenView(state: state, isPresented: $showQuickOpen)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        wordWrap.toggle()
                    } label: {
                        Image(systemName: wordWrap ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
                    }
                    .help("Toggle Word Wrap (\u{2325}Z)")
                    Button {
                        showLineNumbers.toggle()
                    } label: {
                        Image(systemName: showLineNumbers ? "list.number" : "list.bullet")
                    }
                    .help("Toggle Line Numbers (\u{2325}L)")
                    Button {
                        withAnimation { previewUserPref.toggle() }
                    } label: {
                        Image(systemName: previewUserPref ? "rectangle.righthalf.filled" : "rectangle.righthalf.inset.filled")
                    }
                    .help("Toggle Preview (\u{2325}P)")
                }
            }
        }
    }
}
