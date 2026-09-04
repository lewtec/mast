import Testing
@testable import Mast

struct FuzzyTests {
    @Test
    func emptyQueryKeepsOriginalOrder() {
        let items = ["catalog", "cat", "duplicate"]

        #expect(FuzzySearch.ranked(items, query: "", against: { [$0] }) == items)
        #expect(FuzzySearch.ranked(items, query: "   ", against: { [$0] }) == items)
    }

    @Test
    func prefixBeatsSubstringBeatsSubsequence() {
        let ranked = FuzzySearch.ranked(
            ["duplicate", "the catalog", "catalog"],
            query: "cat",
            against: { [$0] }
        )

        #expect(ranked == ["catalog", "the catalog", "duplicate"])
    }

    @Test
    func rejectsCandidatesThatDoNotMatch() {
        #expect(FuzzySearch.score(query: "cat", in: "dog") == nil)
        #expect(FuzzySearch.ranked(["dog", "bird"], query: "cat", against: { [$0] }).isEmpty)
    }

    @Test
    func matchesAgainstAnyProvidedString() {
        struct Row { let title: String; let path: String }
        let rows = [
            Row(title: "Getting started", path: "docs/intro"),
            Row(title: "Changelog", path: "docs/log"),
        ]

        let ranked = FuzzySearch.ranked(rows, query: "intro", against: { [$0.title, $0.path] })

        #expect(ranked.map(\.title) == ["Getting started"])
    }
}
