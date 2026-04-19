# DocumentSearchPrimitive Indexing Lifecycle

Date: 2026-04-18

This note closes the indexing-lifecycle question referenced by ReaderKit v3.
It describes the intended ownership and lifecycle for search indexing in the current ReaderKit stack.

## 1. Decision Summary

Indexing is provider-owned, lazy, in-memory, and per-document.

That means:

- `DocumentSearchPrimitive` owns search UI and controller behavior, not index storage.
- each `DocumentSearchProvider` decides how to prepare searchable material for its document
- search indexes are built on demand when a query needs them, not precomputed globally up front
- session-level aggregation happens in ReaderKit by combining providers, not by creating a shared cross-document index
- persistence is out of scope for the current design

## 2. Why

This keeps the boundary honest:

- renderer/provider code already knows the document structure and anchor model
- different renderers have different costs and opportunities for indexing
- ReaderKit needs coordinated search results, not a second independent indexing system
- most current consumers do not justify persistent or background indexing complexity yet

## 3. Current Model

### UI layer

`DocumentSearchPrimitive` provides:

- `DocumentSearchController`
- `DocumentSearchPresentationState`
- `DocumentSearchBar`
- `SearchPrimitive` query/analyzer/ranking helpers

It does not store or manage document indexes directly.

### Provider layer

Providers are responsible for exposing search matches for one document. In practice they may:

- reuse renderer-native find/search support
- derive searchable blocks from already-built renderer projections
- build an ephemeral in-memory `SearchPrimitive` index the first time a search is requested

This is the right place for indexing because the provider is also responsible for the anchor shape returned in
`SearchMatch`.

### Session layer

ReaderKit's cross-document search coordinator combines document-level provider results into a session-level
surface. It does not replace document-level indexing with a separate global index.

## 4. Deferred Complexity

Still intentionally deferred:

- persistent on-disk indexes
- background precomputation
- cache eviction policy beyond normal in-memory lifecycle
- shared cross-document ranking indexes
- offline index migration/versioning

Those are only worth adding if a real consumer proves that on-demand per-document indexing is too slow or too
shallow.

## 5. Practical Rule

When adding a new `DocumentSearchProvider`:

1. keep indexing local to that provider
2. prefer lazy build over up-front work
3. keep the index in memory unless a real consumer needs persistence
4. return anchors that match the renderer's actual reveal/highlight capabilities

If a provider cannot offer meaningful anchored results, it is not ready to count as a full reader lane.
