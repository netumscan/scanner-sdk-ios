import Foundation

enum RuntimeModuleTaxonomyCatalogFallback {
    private static let lock = NSLock()
    private static var cache: [ModuleTaxonomyKind: [ModuleTaxonomyEntry]] = [:]

    static func entries(for kind: ModuleTaxonomyKind) -> [ModuleTaxonomyEntry] {
        lock.lock()
        if let cached = cache[kind] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        do {
            let loaded = try ScannerSDK.shared.getModuleTaxonomyEntries(kind: kind)
            lock.lock()
            if cache[kind] == nil {
                cache[kind] = loaded
            }
            let result = cache[kind] ?? loaded
            lock.unlock()
            return result
        } catch {
            return []
        }
    }
}
