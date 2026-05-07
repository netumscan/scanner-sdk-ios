import Foundation

enum RuntimeParameterCatalogFallback {
    private static let lock = NSLock()
    private static var cachedNt212xDefinitions: [Nt212xParameterDefinition]?
    private static var cachedNt280hDefinitions: [Nt280hParameterDefinition]?
    private static var cachedSe4750Definitions: [Se4750ParameterDefinition]?

    static var nt212xDefinitions: [Nt212xParameterDefinition] {
        loadCached(&cachedNt212xDefinitions) {
            try ScannerSDK.shared.getNt212xParameterDefinitions()
        }
    }

    static var nt280hDefinitions: [Nt280hParameterDefinition] {
        loadCached(&cachedNt280hDefinitions) {
            try ScannerSDK.shared.getNt280hParameterDefinitions()
        }
    }

    static var se4750Definitions: [Se4750ParameterDefinition] {
        loadCached(&cachedSe4750Definitions) {
            try ScannerSDK.shared.getSe4750ParameterDefinitions()
        }
    }

    private static func loadCached<T>(
        _ cache: inout [T]?,
        loader: () throws -> [T]
    ) -> [T] {
        lock.lock()
        if let cached = cache {
            lock.unlock()
            return cached
        }
        lock.unlock()

        do {
            let loaded = try loader()
            lock.lock()
            if cache == nil {
                cache = loaded
            }
            let result = cache ?? loaded
            lock.unlock()
            return result
        } catch {
            return []
        }
    }
}
