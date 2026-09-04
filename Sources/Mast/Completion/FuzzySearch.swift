import Foundation

enum FuzzySearch {
    static func ranked<Item>(_ items: [Item], query: String, against: (Item) -> [String]) -> [Item] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return items }

        return items.compactMap { item -> (Item, Int)? in
            let best = against(item).compactMap { score(query: needle, in: $0) }.max()
            return best.map { (item, $0) }
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return false
        }
        .map(\.0)
    }

    static func score(query: String, in candidate: String) -> Int? {
        let needle = Array(query.localizedLowercase)
        let haystack = Array(candidate.localizedLowercase)
        guard !needle.isEmpty else { return 0 }
        guard haystack.count >= needle.count else { return nil }

        if let substring = substringScore(needle, in: haystack) {
            return substring
        }
        return subsequenceScore(needle, in: haystack)
    }

    private static func substringScore(_ needle: [Character], in haystack: [Character]) -> Int? {
        guard let start = firstIndex(of: needle, in: haystack) else { return nil }
        var score = 1_000 - start * 3 - (haystack.count - needle.count)
        if start == 0 {
            score += 200
        } else if isBoundary(haystack, start) {
            score += 80
        }
        return score
    }

    private static func firstIndex(of needle: [Character], in haystack: [Character]) -> Int? {
        guard needle.count <= haystack.count else { return nil }
        for start in 0...(haystack.count - needle.count) {
            if haystack[start..<(start + needle.count)].elementsEqual(needle) {
                return start
            }
        }
        return nil
    }

    private static func subsequenceScore(_ needle: [Character], in haystack: [Character]) -> Int? {
        var queryIndex = 0
        var lastMatch = -2
        var score = 0

        for (index, character) in haystack.enumerated() {
            guard character == needle[queryIndex] else { continue }
            score += 10
            if index == lastMatch + 1 {
                score += 15
            }
            if index == 0 || isBoundary(haystack, index) {
                score += 20
            }
            lastMatch = index
            queryIndex += 1
            if queryIndex == needle.count {
                return score - (haystack.count - needle.count)
            }
        }
        return nil
    }

    private static func isBoundary(_ haystack: [Character], _ index: Int) -> Bool {
        guard index > 0 else { return true }
        let previous = haystack[index - 1]
        return !previous.isLetter && !previous.isNumber
    }
}
