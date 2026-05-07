import Foundation

public protocol ModuleTaxonomyMember: Sendable {
    var group: String { get }
    var domainKey: String { get }
    var familyKey: String { get }
    var sectionKey: String { get }
}

public struct ModuleTaxonomySectionGroup<Item: ModuleTaxonomyMember>: Sendable {
    public let key: String
    public let items: [Item]
}

public struct ModuleTaxonomyFamilyGroup<Item: ModuleTaxonomyMember>: Sendable {
    public let key: String
    public let sections: [ModuleTaxonomySectionGroup<Item>]
}

public struct ModuleTaxonomyDomainGroup<Item: ModuleTaxonomyMember>: Sendable {
    public let key: String
    public let families: [ModuleTaxonomyFamilyGroup<Item>]
}

public enum ModuleTaxonomyGrouping {
    public static func groupKeys<Item: ModuleTaxonomyMember>(_ items: [Item]) -> [String] {
        ModuleTaxonomyCatalog.sortKeys(items.map(\.group), for: .group)
    }

    public static func domainGroups<Item: ModuleTaxonomyMember>(
        _ items: [Item],
        sortItemsBy areInIncreasingOrder: ((Item, Item) -> Bool)? = nil
    ) -> [ModuleTaxonomyDomainGroup<Item>] {
        guard !items.isEmpty else {
            return []
        }

        let byDomain = Dictionary(grouping: items, by: \.domainKey)
        let domainKeys = ModuleTaxonomyCatalog.sortKeys(byDomain.keys, for: .domain)

        return domainKeys.map { domainKey in
            let domainItems = byDomain[domainKey] ?? []
            let byFamily = Dictionary(grouping: domainItems, by: \.familyKey)
            let familyKeys = ModuleTaxonomyCatalog.sortKeys(byFamily.keys, for: .family)

            return ModuleTaxonomyDomainGroup(
                key: domainKey,
                families: familyKeys.map { familyKey in
                    let familyItems = byFamily[familyKey] ?? []
                    let bySection = Dictionary(grouping: familyItems, by: \.sectionKey)
                    let sectionKeys = ModuleTaxonomyCatalog.sortKeys(bySection.keys, for: .section)

                    return ModuleTaxonomyFamilyGroup(
                        key: familyKey,
                        sections: sectionKeys.map { sectionKey in
                            let sectionItems = bySection[sectionKey] ?? []
                            return ModuleTaxonomySectionGroup(
                                key: sectionKey,
                                items: areInIncreasingOrder.map { sectionItems.sorted(by: $0) } ?? sectionItems
                            )
                        }
                    )
                }
            )
        }
    }
}

extension Nt212xParameterDefinition: ModuleTaxonomyMember {}
extension Nt280hParameterDefinition: ModuleTaxonomyMember {}
extension Se4750ParameterDefinition: ModuleTaxonomyMember {}
extension Ntc06hSettingDefinition: ModuleTaxonomyMember {}
