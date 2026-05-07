import Foundation
import CNSDK

public enum ModuleTaxonomyKind: UInt32, CaseIterable, Sendable {
    case group = 1
    case domain = 2
    case family = 3
    case section = 4

    var cValue: nsdk_module_taxonomy_kind_t {
        nsdk_module_taxonomy_kind_t(rawValue: rawValue)
    }
}

public struct ModuleTaxonomyEntry: Sendable {
    public let key: String
    public let rank: Int32
    public let localizationKey: String
    public let fallbackDisplayName: String

    internal init(cValue: nsdk_module_taxonomy_entry_t) {
        key = stringFromCStringBuffer(cValue.key)
        rank = cValue.rank
        localizationKey = stringFromCStringBuffer(cValue.localization_key)
        fallbackDisplayName = stringFromCStringBuffer(cValue.fallback_display_name)
    }
}

public enum ModuleTaxonomyCatalog {
    public static func entries(_ kind: ModuleTaxonomyKind) -> [ModuleTaxonomyEntry] {
        RuntimeModuleTaxonomyCatalogFallback.entries(for: kind)
    }

    public static func rank(of kind: ModuleTaxonomyKind, key: String) -> Int32? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return entries(kind).first { $0.key == key }?.rank
    }

    public static func entry(of kind: ModuleTaxonomyKind, key: String) -> ModuleTaxonomyEntry? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return entries(kind).first { $0.key == key }
    }

    public static func sortKeys(
        _ keys: some Sequence<String>,
        for kind: ModuleTaxonomyKind
    ) -> [String] {
        let ranks = Dictionary(uniqueKeysWithValues: entries(kind).map { ($0.key, $0.rank) })
        return Array(Set(keys.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
            .sorted { lhs, rhs in
                let lhsRank = ranks[lhs] ?? Int32.max
                let rhsRank = ranks[rhs] ?? Int32.max
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs < rhs
            }
    }
}
