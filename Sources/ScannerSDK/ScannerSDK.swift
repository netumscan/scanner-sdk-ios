import Foundation
import CNSDK

public final class ScannerSDK: @unchecked Sendable {
    public static let shared = ScannerSDK()
    private static let requiredNativeAbiVersion: UInt32 = 0x010000

    private let lock = NSLock()
    private let abiLock = NSLock()
    private var discoveryHub = StreamHub<DiscoveredDevice>(capacity: nil)
    private var discoveryFailureHub = StreamHub<DiscoveryFailure>()
    private var sessionFailureHub = StreamHub<SessionFailure>()
    private var commandTraceHub = StreamHub<CommandTrace>()
    private var debugHub = StreamHub<String>()
    private var initialized = false
    private var callbacksInstalled = false
    private var discoveredDevices: [String: DiscoveredDevice] = [:]
    private var sessions: [UInt64: ScannerSession] = [:]
    private var pendingSessionEvents: [UInt64: PendingSessionEvents] = [:]
    private var drainingSessions: [UInt64: ScannerSession] = [:]
    internal var beforeSessionEventDeliveryForTesting: ((UInt64) -> Void)?
    private var retiredSessionHandles = Set<UInt64>()
    private var retiredSessionHandleOrder: [UInt64] = []
    private var shutdownInProgress = false
    private let diagnosticsRecorder = DiagnosticsRecorder()
    private var cachedLocalizationEntries: [SdkLocalizationEntry]?
    private var cachedLocalizationIndex: [String: [String: String]]?
    private var nativeAbiValidated = false
    private var nativeAbiValidationError: ScannerError?
    private var lastLocalizationCatalogError: ScannerError?

    private init() {}

    public var discoveries: AsyncStream<DiscoveredDevice> {
        discoveryHub.makeStream()
    }

    public var discoveryFailures: AsyncStream<DiscoveryFailure> {
        discoveryFailureHub.makeStream()
    }

    public var sessionFailures: AsyncStream<SessionFailure> {
        sessionFailureHub.makeStream()
    }

    public var commandTraces: AsyncStream<CommandTrace> {
        commandTraceHub.makeStream()
    }

    public var debugEvents: AsyncStream<String> {
        debugHub.makeStream()
    }

    public var version: String {
        guard let cString = nsdk_version() else { return "" }
        return String(cString: cString)
    }

    /// The most recent error encountered by the non-throwing catalog resolver.
    public var localizationCatalogError: ScannerError? {
        lock.lock()
        defer { lock.unlock() }
        return lastLocalizationCatalogError
    }

    public func localizationEntries() throws -> [SdkLocalizationEntry] {
        lock.lock()
        if let entries = cachedLocalizationEntries {
            lock.unlock()
            return entries
        }
        lock.unlock()

        try ensureNativeAbiCompatible()
        var count: UInt32 = 0
        try nsdkCheck(nsdk_localization_entry_count(&count), operation: "localizationEntries")
        let entries = try loadNativeDefinitions(count: count) { index in
            var entry = makeNsdkLocalizationEntry()
            try nsdkCheck(
                nsdk_localization_entry_get_at(index, &entry),
                operation: "localizationEntries"
            )
            return SdkLocalizationEntry(cValue: entry)
        }

        lock.lock()
        if cachedLocalizationEntries == nil {
            cachedLocalizationEntries = entries
            cachedLocalizationIndex = Self.makeLocalizationIndex(entries)
        }
        lastLocalizationCatalogError = nil
        let result = cachedLocalizationEntries ?? entries
        lock.unlock()
        return result
    }

    public var supportedLocales: [String] {
        (loadLocalizationEntriesForResolution() ?? [])
            .map(\.locale)
            .reduce(into: Set<String>()) { $0.insert($1) }
            .sorted()
    }

    public func localize(
        _ localizationKey: String,
        fallbackDisplayName: String = "",
        locale: Locale = .current
    ) -> String {
        _ = loadLocalizationEntriesForResolution()
        lock.lock()
        let catalog = cachedLocalizationIndex ?? [:]
        lock.unlock()
        return Self.resolveLocalization(
            catalog,
            localizationKey: localizationKey,
            fallbackDisplayName: fallbackDisplayName,
            locale: locale
        )
    }

    public func localize(_ label: CapabilityLabel, locale: Locale = .current) -> String {
        localize(label.localizationKey, fallbackDisplayName: label.displayName, locale: locale)
    }

    public func localize(_ domain: CapabilityDomain, locale: Locale = .current) -> String {
        localize(domain.localizationKey, fallbackDisplayName: domain.displayName, locale: locale)
    }

    internal static func resolveLocalization(
        _ catalog: [String: [String: String]],
        localizationKey: String,
        fallbackDisplayName: String,
        locale: Locale
    ) -> String {
        let translations = catalog[localizationKey] ?? [:]
        for candidate in localeCandidates(locale) {
            if let text = translations[candidate] {
                return text
            }
        }
        return fallbackDisplayName.isEmpty ? localizationKey : fallbackDisplayName
    }

    private func loadLocalizationEntriesForResolution() -> [SdkLocalizationEntry]? {
        do {
            return try localizationEntries()
        } catch let error as ScannerError {
            recordLocalizationCatalogError(error)
        } catch {
            recordLocalizationCatalogError(ScannerError(code: -1, operation: "localization catalog: \(error)"))
        }
        return nil
    }

    private func recordLocalizationCatalogError(_ error: ScannerError) {
        lock.lock()
        lastLocalizationCatalogError = error
        lock.unlock()
        emitDebug("localization catalog error: \(error)")
    }

    internal static func localeCandidates(_ locale: Locale) -> [String] {
        let tag = normalizeLocaleTag(locale.identifier)
        let language = locale.languageCode?.lowercased() ?? "en"
        var candidates = [tag]
        if language == "zh" {
            let script = locale.scriptCode
            let region = locale.regionCode?.uppercased() ?? ""
            if script?.caseInsensitiveCompare("Hans") == .orderedSame ||
                (script == nil && (region.isEmpty || region == "CN" || region == "SG")) {
                candidates.append("zh-Hans")
            }
        }
        let baseParts = tag.split(separator: "-").prefix { $0.count != 1 }.map(String.init)
        for count in stride(from: baseParts.count, through: 1, by: -1) {
            candidates.append(baseParts.prefix(count).joined(separator: "-"))
        }
        candidates.append(language.isEmpty ? "en" : language)
        candidates.append("en")
        return Array(NSOrderedSet(array: candidates)) as? [String] ?? candidates
    }

    private static func normalizeLocaleTag(_ value: String) -> String {
        let bcp47 = value.replacingOccurrences(of: "_", with: "-")
            .split(separator: "@", maxSplits: 1)
            .first.map(String.init) ?? value
        let parts = bcp47.split(separator: "-")
            .map(String.init)
        guard let language = parts.first else { return "en" }
        return ([language.lowercased()] + parts.dropFirst().map { part in
            part.count == 4 ? part.lowercased().capitalized : part.uppercased()
        }).joined(separator: "-")
    }

    private static func makeLocalizationIndex(_ entries: [SdkLocalizationEntry]) -> [String: [String: String]] {
        Dictionary(grouping: entries, by: \.key).mapValues { values in
            Dictionary(uniqueKeysWithValues: values.map { (normalizeLocaleTag($0.locale), $0.text) })
        }
    }

    public func exportNativeLogs(_ request: LogExportRequest = LogExportRequest()) throws -> LogPackage {
        lock.lock()
        let activeSession = sessions.values.first
        lock.unlock()
        return try diagnosticsRecorder.export(
            request: request,
            context: DiagnosticsExportContext(
                platform: "ios",
                bridgeVersion: "swift-wrapper",
                sdkVersion: version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "local-dev" : version,
                activeDeviceId: activeSession?.deviceId,
                activeSelectedModelId: nil,
                activeSessionState: activeSession.map { "\($0.latestState)" }
            )
        )
    }

    public func initialize() throws {
        lock.lock()
        defer { lock.unlock() }
        if initialized { return }
        if shutdownInProgress {
            throw ScannerError(code: 4, operation: "initialize blocked during shutdown")
        }
        try ensureNativeAbiCompatible()
        try nsdkCheck(nsdk_initialize(), operation: "initialize")
        try installCallbacksIfNeeded()
        initialized = true
    }

    private func ensureNativeAbiCompatible() throws {
        abiLock.lock()
        defer { abiLock.unlock() }
        if nativeAbiValidated {
            return
        }
        if let error = nativeAbiValidationError {
            throw error
        }
        if nsdk_abi_is_compatible(Self.requiredNativeAbiVersion) != 0 {
            nativeAbiValidated = true
            return
        }
        let actualAbi = nsdk_abi_version()
        let error = ScannerError(
            code: -1,
            operation: "native ABI mismatch required=0x\(String(Self.requiredNativeAbiVersion, radix: 16)) actual=0x\(String(actualAbi, radix: 16))"
        )
        nativeAbiValidationError = error
        throw error
    }

    public func shutdown() throws {
        lock.lock()
        if !initialized || shutdownInProgress {
            lock.unlock()
            return
        }
        shutdownInProgress = true
        initialized = false
        callbacksInstalled = false
        discoveredDevices.removeAll()
        let activeSessions = Array(sessions.values)
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        drainingSessions.removeAll()
        retiredSessionHandles.removeAll()
        retiredSessionHandleOrder.removeAll()
        let oldDiscoveryHub = discoveryHub
        let oldDiscoveryFailureHub = discoveryFailureHub
        let oldSessionFailureHub = sessionFailureHub
        let oldCommandTraceHub = commandTraceHub
        let oldDebugHub = debugHub
        discoveryHub = StreamHub<DiscoveredDevice>(capacity: nil)
        discoveryFailureHub = StreamHub<DiscoveryFailure>()
        sessionFailureHub = StreamHub<SessionFailure>()
        commandTraceHub = StreamHub<CommandTrace>()
        debugHub = StreamHub<String>()
        lock.unlock()

        for session in activeSessions {
            session.terminateForSdkShutdown()
        }

        _ = nsdk_set_callbacks(nil)
        _ = nsdk_set_discovery_callbacks_v2(nil)

        let shutdownCode = nsdk_shutdown()
        AppleBleRuntime.stop()
        oldDiscoveryHub.finish()
        oldDiscoveryFailureHub.finish()
        oldSessionFailureHub.finish()
        oldCommandTraceHub.finish()
        oldDebugHub.finish()

        lock.lock()
        pendingSessionEvents.removeAll()
        drainingSessions.removeAll()
        shutdownInProgress = false
        lock.unlock()
        try nsdkCheck(shutdownCode, operation: "shutdown")
    }

    public func startDiscovery(
        transports: Set<TransportType> = [.bleGatt],
        selectedModelKey: String = ""
    ) throws {
        try ensureInitialized("startDiscovery")
        lock.lock()
        discoveredDevices.removeAll()
        lock.unlock()
        if transports.contains(.bleGatt) {
            AppleBleRuntime.installTransport()
        }
        let mask = transports.reduce(UInt32(0)) { partial, transport in
            partial | (1 << UInt32(transport.rawValue))
        }
        var request = nsdk_discovery_request_t()
        request.struct_size = UInt32(MemoryLayout<nsdk_discovery_request_t>.size)
        request.transport_mask = mask
        copyCString(selectedModelKey, into: &request.selected_model_key)
        try nsdkCheck(nsdk_discovery_start(&request), operation: "startDiscovery")
    }

    public func stopDiscovery() throws {
        try ensureInitialized("stopDiscovery")
        lock.lock()
        discoveredDevices.removeAll()
        lock.unlock()
        try nsdkCheck(nsdk_discovery_stop(), operation: "stopDiscovery")
    }

    public func connectReady(
        _ device: DiscoveredDevice,
        timeoutMilliseconds: UInt32 = 10_000
    ) async throws -> ScannerSession {
        try await connectReady(
            deviceId: device.deviceId,
            transport: device.transportType,
            selectedModelKey: device.modelKey,
            timeoutMilliseconds: timeoutMilliseconds
        )
    }

    public func connectReady(
        deviceId: String,
        transport: TransportType = .bleGatt,
        selectedModelKey: String = "",
        timeoutMilliseconds: UInt32 = 10_000
    ) async throws -> ScannerSession {
        let session = try connectSession(
            deviceId: deviceId,
            transport: transport,
            selectedModelKey: selectedModelKey
        )
        do {
            try await Task.detached(priority: nil) {
                try session.waitUntilReady(timeoutMilliseconds: timeoutMilliseconds)
            }.value
        } catch {
            try? await session.disconnect()
            throw error
        }
        return session
    }

    private func connectSession(
        deviceId: String,
        transport: TransportType,
        selectedModelKey: String
    ) throws -> ScannerSession {
        try ensureInitialized("connect")
        emitDebug(
            "Connect: deviceId=\(deviceId) transport=\(transport) selectedModel=\(selectedModelKey)"
        )
        if transport == .bleGatt {
            AppleBleRuntime.installTransport()
        }
        var sessionHandle: nsdk_session_handle_t = 0
        try deviceId.withCString { cDeviceID in
            var request = nsdk_connect_request_t()
            request.struct_size = UInt32(MemoryLayout<nsdk_connect_request_t>.size)
            request.device_id = cDeviceID
            request.transport = transport.cValue
            copyCString(selectedModelKey, into: &request.selected_model_key)
            request.model_config_policy = nsdk_model_config_policy_t(NSDK_MODEL_CONFIG_POLICY_ENABLED)
            try nsdkCheck(
                nsdk_session_connect(&request, &sessionHandle),
                operation: "connect"
            )
        }
        let session = ScannerSession(handle: sessionHandle, deviceId: deviceId, transportType: transport, sdk: self)
        return registerSession(session)
    }

    public func getDeviceModelProfile(_ modelKey: String) -> DeviceModelProfile? {
        DeviceModelProfileBridge.load(modelKey)
    }

    public func getSupportedDeviceModels(transport: TransportType) throws -> [SupportedDeviceModel] {
        try DeviceModelProfileBridge.loadSupportedModels(transport: transport)
    }

    public func getCapabilityDomains(modelKey: String, transport: TransportType) throws -> [CapabilityDomain] {
        try modelKey.withCString { cModelKey in
            var count: UInt32 = 0
            try nsdkCheck(
                nsdk_capability_domain_count(cModelKey, transport.cValue, &count),
                operation: "getCapabilityDomains"
            )
            return try loadNativeDefinitions(
                count: count
            ) { index in
                var domain = makeNsdkCapabilityDomain()
                try nsdkCheck(
                    nsdk_capability_domain_get_at(cModelKey, transport.cValue, index, &domain),
                    operation: "getCapabilityDomains"
                )
                return CapabilityDomain(cValue: domain)
            }
        }
    }

    public func getCapabilityLabels(kind: CapabilityLabelKind) throws -> [CapabilityLabel] {
        var count: UInt32 = 0
        try nsdkCheck(
            nsdk_capability_label_count(nsdk_capability_label_kind_t(kind.rawValue), &count),
            operation: "getCapabilityLabels"
        )
        return try loadNativeDefinitions(count: count) { index in
            var label = makeNsdkCapabilityLabel()
            try nsdkCheck(
                nsdk_capability_label_get_at(nsdk_capability_label_kind_t(kind.rawValue), index, &label),
                operation: "getCapabilityLabels"
            )
            return CapabilityLabel(cValue: label)
        }
    }

    public func findCapabilityLabel(kind: CapabilityLabelKind, key: String, ownerKey: String = "") throws -> CapabilityLabel? {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findCapabilityLabel requires non-empty key")
        }
        var label = makeNsdkCapabilityLabel()
        return try ownerKey.withCString { cOwnerKey in
            try key.withCString { cKey in
                let code = nsdk_capability_label_find_by_key(
                    nsdk_capability_label_kind_t(kind.rawValue),
                    cOwnerKey,
                    cKey,
                    &label
                )
                if code == 3 {
                    return nil
                }
                try nsdkCheck(code, operation: "findCapabilityLabel")
                return CapabilityLabel(cValue: label)
            }
        }
    }

    public func getCapabilityEntries(modelKey: String, transport: TransportType) throws -> [CapabilityEntry] {
        try modelKey.withCString { cModelKey in
            var count: UInt32 = 0
            try nsdkCheck(
                nsdk_capability_entry_count(cModelKey, transport.cValue, &count),
                operation: "getCapabilityEntries"
            )
            return try loadNativeDefinitions(
                count: count
            ) { index in
                var entry = makeNsdkCapabilityEntry()
                try nsdkCheck(
                    nsdk_capability_entry_get_at(cModelKey, transport.cValue, index, &entry),
                    operation: "getCapabilityEntries"
                )
                let entryKey = stringFromCStringBuffer(entry.entry_key)
                return CapabilityEntry(
                    cValue: entry,
                    options: try getCapabilityOptions(modelKey: modelKey, transport: transport, entryKey: entryKey)
                )
            }
        }
    }

    public func findCapabilityEntry(modelKey: String, transport: TransportType, entryKey: String) throws -> CapabilityEntry? {
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findCapabilityEntry requires non-empty entry key")
        }
        var entry = makeNsdkCapabilityEntry()
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                let code = nsdk_capability_entry_find_by_key(cModelKey, transport.cValue, cEntryKey, &entry)
                if code == 3 {
                    return nil
                }
                try nsdkCheck(code, operation: "findCapabilityEntry")
                return CapabilityEntry(
                    cValue: entry,
                    options: try getCapabilityOptions(modelKey: modelKey, transport: transport, entryKey: entryKey)
                )
            }
        }
    }

    public func getSettingCodeEntries(modelKey: String, transport: TransportType) throws -> [SettingCodeEntry] {
        try modelKey.withCString { cModelKey in
            var count: UInt32 = 0
            try nsdkCheck(
                nsdk_setting_code_entry_count(cModelKey, transport.cValue, &count),
                operation: "getSettingCodeEntries"
            )
            return try loadNativeDefinitions(
                count: count
            ) { index in
                var entry = makeNsdkSettingCodeEntry()
                try nsdkCheck(
                    nsdk_setting_code_entry_get_at(cModelKey, transport.cValue, index, &entry),
                    operation: "getSettingCodeEntries"
                )
                return SettingCodeEntry(cValue: entry)
            }
        }
    }

    public func findSettingCodeEntry(modelKey: String, transport: TransportType, entryKey: String) throws -> SettingCodeEntry? {
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "findSettingCodeEntry requires non-empty entry key")
        }
        var entry = makeNsdkSettingCodeEntry()
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                try nsdkLookupOrNil(
                    nsdk_setting_code_entry_find_by_key(cModelKey, transport.cValue, cEntryKey, &entry),
                    operation: "findSettingCodeEntry"
                ) {
                    SettingCodeEntry(cValue: entry)
                }
            }
        }
    }

    public func buildSettingCode(
        modelKey: String,
        transport: TransportType,
        entryKey: String,
        value: Data = Data()
    ) throws -> SettingCodeResult {
        guard !entryKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError(code: -1, operation: "buildSettingCode requires non-empty entry key")
        }
        var result = makeNsdkSettingCodeResult()
        try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                let code = value.withUnsafeBytes { rawBuffer in
                    nsdk_build_setting_code(
                        cModelKey,
                        transport.cValue,
                        cEntryKey,
                        value.isEmpty ? nil : rawBuffer.bindMemory(to: UInt8.self).baseAddress,
                        UInt32(value.count),
                        &result
                    )
                }
                try nsdkCheck(code, operation: "buildSettingCode")
            }
        }
        return SettingCodeResult(cValue: result)
    }

    private func getCapabilityOptions(modelKey: String, transport: TransportType, entryKey: String) throws -> [CapabilityOption] {
        guard let entry = try findCapabilityEntryWithoutOptions(modelKey: modelKey, transport: transport, entryKey: entryKey),
              entry.option_count > 0 else {
            return []
        }
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                try loadNativeDefinitions(count: entry.option_count) { index in
                    var option = makeNsdkCapabilityOption()
                    try nsdkCheck(
                        nsdk_capability_option_get_at(cModelKey, transport.cValue, cEntryKey, index, &option),
                        operation: "getCapabilityOptions"
                    )
                    return CapabilityOption(cValue: option)
                }
            }
        }
    }

    private func findCapabilityEntryWithoutOptions(modelKey: String, transport: TransportType, entryKey: String) throws -> nsdk_capability_entry_t? {
        var entry = makeNsdkCapabilityEntry()
        return try modelKey.withCString { cModelKey in
            try entryKey.withCString { cEntryKey in
                try nsdkLookupOrNil(
                    nsdk_capability_entry_find_by_key(cModelKey, transport.cValue, cEntryKey, &entry),
                    operation: "findCapabilityEntry"
                ) {
                    entry
                }
            }
        }
    }

    public func getDataRuleKindLabel(_ kind: DataRuleKind) throws -> DataRuleKindLabel {
        var label = makeNsdkDataRuleKindLabel()
        try nsdkCheck(
            nsdk_data_rule_kind_get_label(kind.cValue, &label),
            operation: "getDataRuleKindLabel"
        )
        return DataRuleKindLabel(cValue: label)
    }

    internal func removeSession(handle: UInt64) {
        lock.lock()
        sessions.removeValue(forKey: handle)
        pendingSessionEvents.removeValue(forKey: handle)
        drainingSessions.removeValue(forKey: handle)
        if retiredSessionHandles.insert(handle).inserted {
            retiredSessionHandleOrder.append(handle)
            if retiredSessionHandleOrder.count > Self.maxRetiredSessionHandles {
                retiredSessionHandles.remove(retiredSessionHandleOrder.removeFirst())
            }
        }
        lock.unlock()
    }

    internal func emitDebug(_ message: String) {
        diagnosticsRecorder.record(
            type: "debug",
            level: message.localizedCaseInsensitiveContains("error") ||
                message.localizedCaseInsensitiveContains("failed") ? "error" : "debug",
            message: message
        )
        debugHub.yield(message)
    }

    internal func emitCommandTrace(_ trace: CommandTrace) {
        diagnosticsRecorder.record(
            type: "commandResult",
            level: trace.acknowledged ? "info" : "error",
            message: trace.operation,
            fields: [
                "commandId": "\(trace.timestampMs)",
                "operationKey": trace.operation,
                "success": trace.acknowledged,
                "errorCode": trace.errorCode,
                "elapsedMs": trace.durationMs,
                "transportType": "\(trace.transportType)",
                "resolvedModelId": trace.resolvedModelKey,
                "capabilityEntryKey": trace.entryKey,
                "requestText": trace.requestText,
                "requestHex": trace.requestHex,
                "responseText": trace.responseText,
                "responseHex": trace.responseHex,
            ],
            happenedAt: Date(timeIntervalSince1970: TimeInterval(trace.timestampMs) / 1000.0)
        )
        commandTraceHub.yield(trace)
    }

    internal func onDiscoveryFailure(_ failure: DiscoveryFailure) {
        diagnosticsRecorder.record(
            type: "failure",
            level: "error",
            message: failure.message,
            fields: [
                "operation": "discovery",
                "transportType": "\(failure.transportType)",
                "errorCode": "\(failure.code.rawValue)",
                "platformError": failure.platformErrorCode,
            ]
        )
        discoveryFailureHub.yield(failure)
    }

    internal func findSession(handle: UInt64) -> ScannerSession? {
        lock.lock()
        defer { lock.unlock() }
        return sessions[handle]
    }

    private func ensureInitialized(_ operation: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard initialized else {
            throw ScannerError(code: -1, operation: "\(operation) requires initialize() first")
        }
    }

    private func registerSession(_ session: ScannerSession) -> ScannerSession {
        lock.lock()
        let activeSession = sessions[session.handle] ?? session
        sessions[session.handle] = activeSession
        retiredSessionHandles.remove(session.handle)
        retiredSessionHandleOrder.removeAll { $0 == session.handle }
        let shouldDrain = drainingSessions[session.handle] == nil
        if shouldDrain { drainingSessions[session.handle] = activeSession }
        lock.unlock()
        if shouldDrain { drainSessionEvents(into: activeSession) }
        return activeSession
    }

    private func dispatchOrQueueSessionEvent(_ event: PendingSessionEvent, handle: UInt64) {
        lock.lock()
        guard !retiredSessionHandles.contains(handle) else {
            lock.unlock()
            return
        }
        let activeSession = sessions[handle]
        let unpublishedHandles = pendingSessionEvents.keys.filter { sessions[$0] == nil }
        if activeSession == nil && pendingSessionEvents[handle] == nil &&
           unpublishedHandles.count >= Self.maxPendingSessionHandles,
           let oldestHandle = unpublishedHandles.first {
            pendingSessionEvents.removeValue(forKey: oldestHandle)
        }
        var pending = pendingSessionEvents[handle] ?? PendingSessionEvents()
        // A terminal event must survive the bounded early-event queue until registration.
        if case .state(let state) = pending.events.last, state == .disconnected || state == .error {
            lock.unlock()
            return
        }
        if activeSession == nil && pending.events.count == Self.maxPendingEventsPerSession {
            pending.events.removeFirst()
        }
        pending.events.append(event)
        pendingSessionEvents[handle] = pending
        let drainer = activeSession.flatMap { session -> ScannerSession? in
            guard drainingSessions[handle] == nil else { return nil }
            drainingSessions[handle] = session
            return session
        }
        lock.unlock()
        if let drainer { drainSessionEvents(into: drainer) }
    }

    private func drainSessionEvents(into session: ScannerSession) {
        while true {
            lock.lock()
            guard sessions[session.handle] === session, drainingSessions[session.handle] === session else {
                lock.unlock()
                return
            }
            guard var pending = pendingSessionEvents[session.handle], !pending.events.isEmpty else {
                pendingSessionEvents.removeValue(forKey: session.handle)
                drainingSessions.removeValue(forKey: session.handle)
                lock.unlock()
                return
            }
            let event = pending.events.removeFirst()
            pendingSessionEvents[session.handle] = pending
            lock.unlock()
            // Delivery may reenter the SDK. Never hold the routing lock here.
            beforeSessionEventDeliveryForTesting?(session.handle)
            guard findSession(handle: session.handle) === session else { continue }
            event.deliver(into: session)
        }
    }

    private static let maxPendingEventsPerSession = 32
    private static let maxPendingSessionHandles = 8
    private static let maxRetiredSessionHandles = 128

    private func installCallbacksIfNeeded() throws {
        guard !callbacksInstalled else { return }
        let userData = Unmanaged.passUnretained(self).toOpaque()
        var callbacks = makeNsdkCallbacks()
        callbacks.discovery_failure_callback = nsdk_swift_discovery_failure_callback
        callbacks.discovery_failure_user_data = userData
        callbacks.session_state_callback = nsdk_swift_state_callback
        callbacks.session_state_user_data = userData
        callbacks.scan_data_callback = nsdk_swift_scan_callback
        callbacks.scan_data_user_data = userData
        callbacks.session_failure_callback = nsdk_swift_session_failure_callback
        callbacks.session_failure_user_data = userData
        callbacks.session_initialization_stage_callback = nsdk_swift_session_initialization_stage_callback
        callbacks.session_initialization_stage_user_data = userData
        callbacks.command_trace_callback = nsdk_swift_command_trace_callback
        callbacks.command_trace_user_data = userData
        callbacks.log_callback = nsdk_swift_log_callback
        callbacks.log_user_data = userData
        try nsdkCheck(nsdk_set_callbacks(&callbacks), operation: "installCallbacks")
        var discoveryCallbacks = nsdk_discovery_callbacks_v2_t()
        discoveryCallbacks.struct_size = UInt32(MemoryLayout<nsdk_discovery_callbacks_v2_t>.size)
        discoveryCallbacks.discovered_device_callback = nsdk_swift_discovered_device_callback
        discoveryCallbacks.user_data = userData
        try nsdkCheck(nsdk_set_discovery_callbacks_v2(&discoveryCallbacks), operation: "installDiscoveryCallbacksV2")
        callbacksInstalled = true
    }

    fileprivate func handleDiscovery(_ device: DiscoveredDevice) {
        if device.transportType == .bleGatt && device.deviceId.isEmpty { return }
        lock.lock()
        // BLE changes and duplicates are handled by the shared Core cache.
        let existing = discoveredDevices[device.deviceId]
        let shouldYield = device.transportType == .bleGatt || existing == nil ||
            existing?.name != device.name || existing?.modelKey != device.modelKey ||
            existing?.matchReason != device.matchReason
        if shouldYield { discoveredDevices[device.deviceId] = device }
        lock.unlock()
        if shouldYield { discoveryHub.yield(device) }
    }

    fileprivate func handleState(handle: UInt64, state: SessionState) {
        let session = findSession(handle: handle)
        diagnosticsRecorder.record(
            type: "sessionState",
            message: "\(state)",
            fields: [
                "deviceId": session?.deviceId,
                "state": "\(state)",
            ]
        )
        dispatchOrQueueSessionEvent(.state(state), handle: handle)
    }

    private func recordScanSummary(
        handle: UInt64,
        timestampMs: UInt64,
        barcodeType: Int32,
        textBytes: Data,
        rawBytes: Data
    ) {
        let text = String(data: textBytes, encoding: .utf8) ?? String(decoding: textBytes, as: UTF8.self)
        diagnosticsRecorder.record(
            type: "scanSummary",
            fields: [
                "deviceId": findSession(handle: handle)?.deviceId,
                "rawBytesLength": rawBytes.count,
                "textBytesLength": textBytes.count,
                "textHash": sha256Short(text),
                "symbology": "\(barcodeType)",
                "rawBytes": [UInt8](rawBytes),
                "text": text,
            ],
            happenedAt: Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)
        )
    }

    fileprivate func handleScan(handle: UInt64, scanData: nsdk_scan_data_t) {
        let textBytes = scanData.text_bytes.map { Data(bytes: $0, count: Int(scanData.text_size)) } ?? Data()
        let rawBytes = scanData.raw_bytes.map { Data(bytes: $0, count: Int(scanData.raw_size)) } ?? Data()
        recordScanSummary(
            handle: handle,
            timestampMs: scanData.timestamp_ms,
            barcodeType: scanData.barcode_type,
            textBytes: textBytes,
            rawBytes: rawBytes
        )
        dispatchOrQueueSessionEvent(
            .scan(
                PendingScanEvent(
                    timestampMs: scanData.timestamp_ms,
                    barcodeType: scanData.barcode_type,
                    textBytes: textBytes,
                    rawBytes: rawBytes
                )
            ),
            handle: handle
        )
    }

    fileprivate static func describeTransportFailure(
        transport: TransportType,
        issue: TransportIssue
    ) -> String {
        switch transport {
        case .bleGatt:
            switch issue {
            case .bleServiceDiscoveryStartFailed: return "BLE session failed: service discovery could not start"
            case .bleServiceDiscoveryFailed: return "BLE session failed: service discovery failed"
            case .bleNotifyServiceMissing: return "BLE session failed: notify service missing"
            case .bleNotifyCharacteristicMissing: return "BLE session failed: notify characteristic missing"
            case .bleNotificationEnableFailed: return "BLE session failed: enabling notifications failed"
            case .bleNotifyDescriptorMissing: return "BLE session failed: notify descriptor missing"
            case .bleNotifyDescriptorWriteFailed: return "BLE session failed: notify descriptor write failed"
            case .connectionTimeout: return "BLE session failed: connection timed out"
            case .bleGattFailure: return "BLE session failed: platform GATT failure"
            case .platformError: return "BLE session failed: platform connection status error"
            case .unknown: return "BLE session failed: unknown transport error"
            }
        case .usbHid:
            return issue == .platformError
                ? "UsbHid session failed: platform transport status error"
                : "UsbHid session failed: transport error"
        case .usbSerial:
            return issue == .platformError
                ? "UsbSerial session failed: platform transport status error"
                : "UsbSerial session failed: transport error"
        case .sppClassic:
            return issue == .platformError
                ? "SppClassic session failed: platform transport status error"
                : "SppClassic session failed: transport error"
        }
    }
}

extension ScannerSDK {
    internal static func makeTestingInstance() -> ScannerSDK {
        ScannerSDK()
    }

    internal func makeTestingSession(
        handle: UInt64,
        deviceId: String = "",
        transportType: TransportType = .bleGatt
    ) -> ScannerSession {
        ScannerSession(handle: handle, deviceId: deviceId, transportType: transportType, sdk: self)
    }

    internal func registerSessionForTesting(_ session: ScannerSession) -> ScannerSession {
        registerSession(session)
    }

    internal func registerSessionForTesting(handle: UInt64) -> ScannerSession {
        registerSessionForTesting(makeTestingSession(handle: handle))
    }

    internal func resetSessionsForTesting() {
        lock.lock()
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        drainingSessions.removeAll()
        retiredSessionHandles.removeAll()
        retiredSessionHandleOrder.removeAll()
        lock.unlock()
    }

    internal func pendingSessionEventCountForTesting(handle: UInt64) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return pendingSessionEvents[handle]?.events.count ?? 0
    }

    internal func terminateSessionsForSdkShutdownForTesting() {
        lock.lock()
        let activeSessions = Array(sessions.values)
        sessions.removeAll()
        pendingSessionEvents.removeAll()
        drainingSessions.removeAll()
        lock.unlock()
        for session in activeSessions {
            session.terminateForSdkShutdown()
        }
    }

    internal func simulatePendingState(_ state: SessionState, handle: UInt64) {
        handleState(handle: handle, state: state)
    }

    internal func simulatePendingFailure(
        handle: UInt64,
        transport: TransportType,
        issue: TransportIssue,
        platformErrorCode: Int32
    ) {
        var failure = nsdk_session_failure_t()
        failure.transport = transport.cValue
        failure.issue = nsdk_transport_issue_t(issue.rawValue)
        failure.platform_error = platformErrorCode
        failure.platform_error_available = 1
        handleSessionFailure(handle: handle, failure: failure)
    }

    internal func simulatePendingScan(
        handle: UInt64,
        timestampMs: UInt64,
        barcodeType: Int32,
        textBytes: Data,
        rawBytes: Data
    ) {
        recordScanSummary(
            handle: handle,
            timestampMs: timestampMs,
            barcodeType: barcodeType,
            textBytes: textBytes,
            rawBytes: rawBytes
        )
        dispatchOrQueueSessionEvent(
            .scan(
                PendingScanEvent(
                    timestampMs: timestampMs,
                    barcodeType: barcodeType,
                    textBytes: textBytes,
                    rawBytes: rawBytes
                )
            ),
            handle: handle
        )
    }

    internal func simulatePendingInitializationStage(
        handle: UInt64,
        selectedModelKey: String,
        stage: SessionInitializationStage,
        timestampMs: UInt64,
        traceId: UInt64,
        success: Bool,
        errorCode: Int32,
        message: String?
    ) {
        dispatchOrQueueSessionEvent(
            .initializationStage(
                PendingSessionInitializationStage(
                    selectedModelKey: selectedModelKey,
                    stage: stage,
                    timestampMs: timestampMs,
                    traceId: traceId,
                    success: success,
                    errorCode: errorCode,
                    message: message
                )
            ),
            handle: handle
        )
    }

    fileprivate func handleSessionFailure(handle: UInt64, failure: nsdk_session_failure_t) {
        let transport = TransportType(rawValue: failure.transport) ?? .bleGatt
        let issue = TransportIssue(rawValue: failure.issue) ?? .unknown
        let activeSession = findSession(handle: handle)
        let sessionFailure = SessionFailure(
            sessionHandle: handle,
            deviceId: activeSession?.deviceId ?? "",
            transportType: transport,
            issue: issue,
            message: ScannerSDK.describeTransportFailure(transport: transport, issue: issue),
            platformErrorCode: failure.platform_error_available != 0 ? failure.platform_error : nil
        )
        diagnosticsRecorder.record(
            type: "failure",
            level: "error",
            message: sessionFailure.message,
            fields: [
                "deviceId": sessionFailure.deviceId,
                "transportType": "\(sessionFailure.transportType)",
                "transportIssue": "\(sessionFailure.issue.rawValue)",
                "platformError": sessionFailure.platformErrorCode,
            ]
        )
        sessionFailureHub.yield(sessionFailure)
        dispatchOrQueueSessionEvent(
            .failure(
                PendingSessionFailure(
                    transport: transport,
                    issue: issue,
                    platformErrorCode: failure.platform_error_available != 0 ? failure.platform_error : nil
                )
            ),
            handle: handle
        )
    }

    fileprivate func handleSessionInitializationStage(handle: UInt64, event: nsdk_session_initialization_stage_event_t) {
        let stageEvent = SessionInitializationStageEvent(
            sessionHandle: handle,
            deviceId: findSession(handle: handle)?.deviceId ?? "",
            selectedModelKey: stringFromCStringBuffer(event.selected_model_key),
            stage: SessionInitializationStage(cValue: event.stage),
            timestampMs: event.timestamp_ms,
            traceId: event.trace_id,
            success: event.success != 0,
            errorCode: event.error_code,
            message: stringFromCStringBuffer(event.message).isEmpty ? nil : stringFromCStringBuffer(event.message)
        )
        dispatchOrQueueSessionEvent(
            .initializationStage(
                PendingSessionInitializationStage(
                    selectedModelKey: stageEvent.selectedModelKey,
                    stage: stageEvent.stage,
                    timestampMs: stageEvent.timestampMs,
                    traceId: stageEvent.traceId,
                    success: stageEvent.success,
                    errorCode: stageEvent.errorCode,
                    message: stageEvent.message
                )
            ),
            handle: handle
        )
    }

    fileprivate func handleCommandTrace(handle: UInt64, trace: nsdk_command_trace_t) {
        let value = CommandTrace(cValue: trace)
        emitCommandTrace(value)
        dispatchOrQueueSessionEvent(.trace(value), handle: handle)
    }

    fileprivate func handleNativeLog(level: Int32, message: String) {
        if message.hasPrefix("[NSDKAppleBLE]") {
            let bleMessage = message
                .replacingOccurrences(of: "[NSDKAppleBLE]", with: "BLE")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            emitDebug(bleMessage)
            return
        }
        let prefix = level >= 3 ? "core-error:" : "core:"
        emitDebug("\(prefix) \(message)")
    }
}

private struct PendingScanEvent {
    let timestampMs: UInt64
    let barcodeType: Int32
    let textBytes: Data
    let rawBytes: Data
}

private struct PendingSessionFailure {
    let transport: TransportType
    let issue: TransportIssue
    let platformErrorCode: Int32?
}

private struct PendingSessionInitializationStage {
    let selectedModelKey: String
    let stage: SessionInitializationStage
    let timestampMs: UInt64
    let traceId: UInt64
    let success: Bool
    let errorCode: Int32
    let message: String?
}

private enum PendingSessionEvent {
    case trace(CommandTrace)
    case state(SessionState)
    case scan(PendingScanEvent)
    case failure(PendingSessionFailure)
    case initializationStage(PendingSessionInitializationStage)

    func deliver(into session: ScannerSession) {
        switch self {
        case .trace(let trace):
            session.onCommandTrace(trace)
        case .state(let state):
            session.onStateChanged(state)
        case .scan(let scan):
            session.onScanEvent(
                timestampMs: scan.timestampMs,
                barcodeType: scan.barcodeType,
                textBytes: scan.textBytes,
                rawBytes: scan.rawBytes
            )
        case .failure(let failure):
            session.onFailure(
                SessionFailure(
                    sessionHandle: session.handle,
                    deviceId: session.deviceId,
                    transportType: failure.transport,
                    issue: failure.issue,
                    message: ScannerSDK.describeTransportFailure(transport: failure.transport, issue: failure.issue),
                    platformErrorCode: failure.platformErrorCode
                )
            )
        case .initializationStage(let stage):
            session.onInitializationStage(
                SessionInitializationStageEvent(
                    sessionHandle: session.handle,
                    deviceId: session.deviceId,
                    selectedModelKey: stage.selectedModelKey,
                    stage: stage.stage,
                    timestampMs: stage.timestampMs,
                    traceId: stage.traceId,
                    success: stage.success,
                    errorCode: stage.errorCode,
                    message: stage.message
                )
            )
        }
    }
}

private struct PendingSessionEvents {
    var events: [PendingSessionEvent] = []
}

private func nsdk_swift_discovery_failure_callback(
    failure: UnsafePointer<nsdk_discovery_failure_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let failure else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.onDiscoveryFailure(DiscoveryFailure(cValue: failure.pointee))
}

private func nsdk_swift_discovered_device_callback(
    device: UnsafePointer<nsdk_discovered_device_v2_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let device,
          device.pointee.struct_size >= MemoryLayout<nsdk_discovered_device_v2_t>.size else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleDiscovery(DiscoveredDevice(cValue: device.pointee))
}

private func nsdk_swift_state_callback(
    session: nsdk_session_handle_t,
    state: nsdk_session_state_t,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleState(handle: session, state: SessionState(cValue: state))
}

private func nsdk_swift_scan_callback(
    session: nsdk_session_handle_t,
    scanData: UnsafePointer<nsdk_scan_data_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let scanData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleScan(handle: session, scanData: scanData.pointee)
}

private func nsdk_swift_session_failure_callback(
    session: nsdk_session_handle_t,
    failure: UnsafePointer<nsdk_session_failure_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let failure else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleSessionFailure(handle: session, failure: failure.pointee)
}

private func nsdk_swift_session_initialization_stage_callback(
    session: nsdk_session_handle_t,
    event: UnsafePointer<nsdk_session_initialization_stage_event_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let event else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleSessionInitializationStage(handle: session, event: event.pointee)
}

private func nsdk_swift_command_trace_callback(
    session: nsdk_session_handle_t,
    trace: UnsafePointer<nsdk_command_trace_t>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData, let trace else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleCommandTrace(handle: session, trace: trace.pointee)
}

private func nsdk_swift_log_callback(
    level: Int32,
    message: UnsafePointer<CChar>?,
    userData: UnsafeMutableRawPointer?
) {
    guard let userData else { return }
    let sdk = Unmanaged<ScannerSDK>.fromOpaque(userData).takeUnretainedValue()
    sdk.handleNativeLog(level: level, message: message.map(String.init(cString:)) ?? "")
}
