import Testing
import SwiftUI
import ContentModelPrimitive
@testable import DocumentSearchPrimitive
import SearchPrimitive

private typealias SurfaceSearchQuery = ContentModelPrimitive.SearchQuery

private struct StubDocumentSearchProvider: DocumentSearchProvider {
    let documentID: DocumentID
    let matchesByQuery: [String: [SearchMatch]]

    init(
        documentID: DocumentID = "doc-1",
        matchesByQuery: [String: [SearchMatch]]
    ) {
        self.documentID = documentID
        self.matchesByQuery = matchesByQuery
    }

    func search(query: SurfaceSearchQuery) -> AsyncThrowingStream<SearchMatch, Error> {
        let matches = matchesByQuery[query.text, default: []]
        return AsyncThrowingStream { continuation in
            for match in matches {
                continuation.yield(match)
            }
            continuation.finish()
        }
    }
}

private struct StubIndexedDocument: Indexable, Sendable {
    let id: String
    let title: String
    let body: String

    func indexableFields() -> [IndexableField] {
        [
            IndexableField(name: "title", value: title, options: .init(boost: 2.0)),
            IndexableField(name: "body", value: body),
        ]
    }
}

@Test func documentSearchPresentationStateDefaultsAreStable() {
    let state = DocumentSearchPresentationState()

    #expect(state.isVisible == false)
    #expect(state.query.isEmpty)
    #expect(state.resultCount == 0)
    #expect(state.currentResultIndex == nil)
}

@MainActor
@Test func documentSearchControllerCollectsProviderMatches() async {
    let provider = StubDocumentSearchProvider(matchesByQuery: [
        "swift": [
            SearchMatch(
                id: "match-1",
                text: "Swift",
                anchor: .text(TextAnchor(startOffset: 0, length: 5, quotedText: "Swift")),
                range: 0..<5
            ),
            SearchMatch(
                id: "match-2",
                text: "SwiftUI",
                anchor: .text(TextAnchor(startOffset: 10, length: 7, quotedText: "SwiftUI")),
                range: 10..<17
            ),
        ]
    ])

    let controller = DocumentSearchController(provider: provider)
    controller.setVisible(true)
    controller.updateQuery("swift")
    try? await Task.sleep(for: .milliseconds(350))

    #expect(controller.presentationState.isVisible == true)
    #expect(controller.presentationState.resultCount == 2)
    #expect(controller.presentationState.currentResultIndex == 0)
    #expect(controller.currentMatch?.id == "match-1")

    controller.move(delta: 1)

    #expect(controller.presentationState.currentResultIndex == 1)
    #expect(controller.currentMatch?.id == "match-2")
}

@MainActor
@Test func documentSearchControllerDismissResetsState() async {
    let provider = StubDocumentSearchProvider(matchesByQuery: [
        "reader": [
            SearchMatch(
                id: "match-1",
                text: "Reader",
                anchor: .text(TextAnchor(startOffset: 4, length: 6, quotedText: "Reader")),
                range: 4..<10
            )
        ]
    ])

    let controller = DocumentSearchController(provider: provider)
    controller.setVisible(true)
    controller.updateQuery("reader")
    try? await Task.sleep(for: .milliseconds(350))
    controller.dismiss()

    #expect(controller.presentationState == DocumentSearchPresentationState())
    #expect(controller.matches.isEmpty)
    #expect(controller.currentMatch == nil)
}

@MainActor
@Test func documentSearchBarPublicSurfaceLoads() {
    _ = DocumentSearchBar(
        query: .constant("swift"),
        resultCount: 3,
        currentResultIndex: 1,
        onNext: {},
        onPrevious: {},
        onDismiss: {}
    )
}

@Test func documentSearchSearchPrimitiveSupportHandlesFuzzyAndStemmedQueries() async throws {
    let index = SearchIndex<StubIndexedDocument>(
        analyzer: DocumentSearchSearchPrimitiveSupport.analyzer,
        rankingAlgorithm: DocumentSearchSearchPrimitiveSupport.rankingAlgorithm
    )

    await index.index([
        StubIndexedDocument(
            id: "doc-1",
            title: "Swift concurrency",
            body: "Structured concurrency keeps Swift code responsive."
        ),
        StubIndexedDocument(
            id: "doc-2",
            title: "Running log",
            body: "The runners were running every morning."
        ),
    ])

    let fuzzyQuery = try #require(
        DocumentSearchSearchPrimitiveSupport.query(for: "concurency")
    )
    let fuzzyResults = try await index.search(fuzzyQuery, limit: 10)
    #expect(fuzzyResults.first?.document.id == "doc-1")

    let stemmedQuery = try #require(
        DocumentSearchSearchPrimitiveSupport.query(for: "run")
    )
    let stemmedResults = try await index.search(stemmedQuery, limit: 10)
    #expect(stemmedResults.first?.document.id == "doc-2")
}
