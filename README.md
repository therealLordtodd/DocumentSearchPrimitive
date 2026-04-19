# DocumentSearchPrimitive

`DocumentSearchPrimitive` is the shared in-document search surface for the portfolio. It provides the search bar UI, the result-navigation controller, and an `AsyncThrowingStream`-based search protocol that renderer primitives expose via `DocumentSearchProvider` in `ContentModelPrimitive`.

Use it when a host needs "find in this document" UX in a reader. Do not rebuild a search bar.

## What The Package Gives You

- `DocumentSearchController` — the `@MainActor` `ObservableObject` that owns search state and navigation
- `DocumentSearchPresentationState` — the typed state bundle (isVisible, query, resultCount, currentResultIndex)
- `DocumentSearchSearchPrimitiveSupport` — preset `Analyzer`, `RankingAlgorithm`, and query builder that turn user text into `SearchPrimitive.SearchQuery` with BM25 ranking, stemming, stop-word filtering, and fuzzy matching
- shared SwiftUI views for the search bar and result navigation

## When To Use It

- You are using `ReaderView` — the primitive is composed internally; no direct import needed
- You are building a custom reader and want single-document search with the same UX as every portfolio reader
- You are implementing a `DocumentSearchProvider` in a renderer primitive and want the shared query-shaping helpers

## When Not To Use It

- You need cross-document search — that is a `ReaderKit` concern (`ReaderSessionSearchCoordinator`) that aggregates multiple `DocumentSearchProvider` instances
- You need filesystem search — use `LocalSearchKit`
- You need full-text indexing on arbitrary structured data — use `SearchPrimitive` directly; this package is the reader-surface UX on top

## Install

```swift
dependencies: [
    .package(path: "../DocumentSearchPrimitive"),
],
targets: [
    .target(
        name: "MyReaderHost",
        dependencies: ["DocumentSearchPrimitive"]
    )
]
```

Depends on `ContentModelPrimitive` (for `DocumentSearchProvider`), `ReaderChromeThemePrimitive` (for theming), and `SearchPrimitive` (for the search engine).

## How It Fits

1. A renderer primitive (Markdown, PDF, HTML, etc.) conforms to `DocumentSearchProvider` from `ContentModelPrimitive` and exposes its document content for indexing.
2. `DocumentSearchPrimitive` builds a `SearchPrimitive`-backed query using `DocumentSearchSearchPrimitiveSupport.query(for:)`, with BM25 ranking, stemming, and fuzzy matching.
3. Native renderer find (PDFKit, WKWebView find, NSTextView find) handles the visible highlighting and scroll-to-match.
4. `DocumentSearchController` coordinates the query → results → navigation lifecycle.

## Basic Usage

### Inside `ReaderView`

Already wired. The search trigger in `ReaderToolbarPrimitive` shows / hides the search UI, and the controller is held by `ReaderComposer`.

### In a custom reader surface

```swift
import DocumentSearchPrimitive
import ContentModelPrimitive
import SwiftUI

struct CustomReader: View {
    @StateObject private var controller: DocumentSearchController

    init(provider: any DocumentSearchProvider) {
        _controller = StateObject(wrappedValue: DocumentSearchController(provider: provider))
    }

    var body: some View {
        VStack {
            DocumentSearchBar(controller: controller)
            ReaderContent(controller: controller)
        }
    }
}
```

## Integration Guide

Full reader-stack story — how this primitive interacts with renderer-provider conformances, cross-document search aggregation, and reveal routing:

- `Packages/ReaderKit/docs/reader-stack-integration-guide.md`

## Design Notes

Search matching uses `SearchPrimitive`'s engine from day one, not ad hoc substring matching. That means every reader-stack consumer gets BM25 ranking, stemming-aware matches, fuzzy matching with distance-scaled Levenshtein tolerance, and phrase queries — for free. Renderer primitives that conform to `DocumentSearchProvider` can reuse `DocumentSearchSearchPrimitiveSupport.analyzer` and `DocumentSearchSearchPrimitiveSupport.rankingAlgorithm` for consistency.

Cross-document search lives one level up in `ReaderKit` (`ReaderSessionSearchCoordinator`) and aggregates `DocumentSearchProvider` instances across a session. This primitive is single-document on purpose.
