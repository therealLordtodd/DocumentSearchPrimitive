# DocumentSearchPrimitive — Agent Instructions

Keep this package focused on reusable reader search chrome and provider-bound search state.

## Package Purpose

`DocumentSearchPrimitive` owns the shared in-document search surface — UI bar, result controller, and `SearchPrimitive`-backed query shaping. It consumes renderer-exposed `DocumentSearchProvider` conformances (defined in `ContentModelPrimitive`) and presents the single-document search experience. Cross-document search aggregation lives in `ReaderKit`.

**Tech stack:** Swift 6.0 / SwiftUI / Foundation.

## Key Types

- `DocumentSearchController` — `@MainActor` `ObservableObject` owning search state and navigation
- `DocumentSearchPresentationState` — typed state (visibility, query, result count, current index)
- `DocumentSearchSearchPrimitiveSupport` — preset analyzer (lowercase + stop-word + stemming), ranking (BM25), and query builder
- shared search bar and navigation SwiftUI views

## Dependencies

- `ContentModelPrimitive` — provides `DocumentSearchProvider` protocol
- `ReaderChromeThemePrimitive` — theming via environment
- `SearchPrimitive` — BM25 ranking, fuzzy matching, stemming, phrase queries

## Architecture Rules

- **Single-document only.** Cross-document aggregation is a `ReaderKit` concern (`ReaderSessionSearchCoordinator`).
- **Use `SearchPrimitive` for ranking.** Do not roll ad hoc substring matching. The shared analyzer and query builder ensure consistent behavior across every reader-stack consumer.
- **Native find handles visuals.** Rendering highlights and scroll-to-match are the renderer's job (PDFKit, WKWebView, NSTextView). This primitive coordinates; it does not paint highlights itself.
- **Providers over UI composition.** CRK's cross-doc coordinator aggregates `DocumentSearchProvider` instances — not `DocumentSearchController` instances and certainly not UI views.

## Primary Documentation

- Host-facing usage + API reference: `/Users/todd/Programming/Packages/DocumentSearchPrimitive/README.md`
- Portfolio integration guide: `/Users/todd/Programming/Packages/ReaderKit/docs/reader-stack-integration-guide.md`

## Primitives-First Development

1. Is the addition in-document search-shaped, or cross-document-shaped? Cross-document belongs in `ReaderKit`.
2. Is it renderer-specific (highlight painting, scroll coordination)? That belongs in a renderer primitive.
3. Is it engine work (tokenization, ranking, index)? That belongs in `SearchPrimitive`.

## GitHub Repository Visibility

- This repository is **private**. Do not change visibility without Todd's explicit request.
