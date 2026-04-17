import SwiftUI
import ContentModelPrimitive
import ReaderChromeThemePrimitive

public struct DocumentSearchPresentationState: Sendable, Equatable {
    public var isVisible: Bool
    public var query: String
    public var resultCount: Int
    public var currentResultIndex: Int?

    public init(
        isVisible: Bool = false,
        query: String = "",
        resultCount: Int = 0,
        currentResultIndex: Int? = nil
    ) {
        self.isVisible = isVisible
        self.query = query
        self.resultCount = resultCount
        self.currentResultIndex = currentResultIndex
    }
}

@MainActor
public final class DocumentSearchController: ObservableObject {
    @Published public private(set) var presentationState = DocumentSearchPresentationState()
    @Published public private(set) var matches: [SearchMatch] = []

    public let documentID: DocumentID

    private let provider: any DocumentSearchProvider
    private var searchTask: Task<Void, Never>?

    public init(provider: any DocumentSearchProvider) {
        self.provider = provider
        self.documentID = provider.documentID
    }

    public var currentMatch: SearchMatch? {
        guard let currentResultIndex = presentationState.currentResultIndex,
              matches.indices.contains(currentResultIndex) else {
            return nil
        }
        return matches[currentResultIndex]
    }

    public func setVisible(_ visible: Bool) {
        if visible {
            presentationState.isVisible = true
        } else if presentationState.isVisible {
            dismiss()
        }
    }

    public func updateQuery(_ query: String) {
        presentationState.query = query
        presentationState.currentResultIndex = nil
        scheduleSearch()
    }

    public func move(delta: Int) {
        guard !matches.isEmpty else { return }

        let nextIndex: Int
        if let currentResultIndex = presentationState.currentResultIndex {
            nextIndex = (currentResultIndex + delta + matches.count) % matches.count
        } else {
            nextIndex = 0
        }

        presentationState.currentResultIndex = nextIndex
    }

    public func dismiss() {
        searchTask?.cancel()
        searchTask = nil
        matches = []
        presentationState = DocumentSearchPresentationState()
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        matches = []
        presentationState.resultCount = 0
        presentationState.currentResultIndex = nil

        let normalizedQuery = presentationState.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else { return }

        presentationState.isVisible = true

        searchTask = Task { [provider] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            var collectedMatches: [SearchMatch] = []

            do {
                for try await match in provider.search(query: SearchQuery(text: normalizedQuery)) {
                    guard !Task.isCancelled else { return }
                    collectedMatches.append(match)
                }
            } catch {
                guard !Task.isCancelled else { return }
            }

            guard !Task.isCancelled else { return }

            matches = collectedMatches
            presentationState.resultCount = collectedMatches.count
            presentationState.currentResultIndex = collectedMatches.isEmpty ? nil : 0
        }
    }
}

public struct DocumentSearchBar: View {
    @Binding public var query: String

    public var resultCount: Int
    public var currentResultIndex: Int?
    public var placeholder: String
    public var onNext: () -> Void
    public var onPrevious: () -> Void
    public var onDismiss: () -> Void

    @FocusState private var isFieldFocused: Bool
    @Environment(\.readerChromeTheme) private var theme

    public init(
        query: Binding<String>,
        resultCount: Int,
        currentResultIndex: Int?,
        placeholder: String = "Find in document\u{2026}",
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._query = query
        self.resultCount = resultCount
        self.currentResultIndex = currentResultIndex
        self.placeholder = placeholder
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: theme.spacing.small) {
            TextField(placeholder, text: $query)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .focused($isFieldFocused)
                .onSubmit { onNext() }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFieldFocused = true
                    }
                }

            if query.count >= 2 {
                if resultCount > 0, let currentResultIndex {
                    Text("\(currentResultIndex + 1) of \(resultCount)")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.secondaryText)
                        .monospacedDigit()
                } else {
                    Text("No results")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.secondaryText)
                }
            }

            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(theme.typography.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .disabled(resultCount == 0)
            .help("Previous match (\u{21E7}\u{2318}G)")

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(theme.typography.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .disabled(resultCount == 0)
            .help("Next match (\u{2318}G)")

            Button("Done") { onDismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colors.infoTint)
        }
        .padding(.horizontal, theme.spacing.medium)
        .padding(.vertical, theme.spacing.small)
        .background(theme.colors.inputBackground, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: theme.colors.shadow.opacity(0.15), radius: 4, y: 2)
        .documentSearchEscapeDismiss(onDismiss: onDismiss)
    }
}

private extension View {
    @ViewBuilder
    func documentSearchEscapeDismiss(onDismiss: @escaping () -> Void) -> some View {
        #if os(macOS)
        if #available(macOS 14.0, *) {
            self.onKeyPress(.escape) {
                onDismiss()
                return .handled
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}
