import XCTest
import CNSDK
@testable import ScannerSDK

final class ScannerSDKTests: XCTestCase {
    func testReadyArrivingDuringPendingReplayCannotBeOverwritten() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 701)
        var states = session.state.makeAsyncIterator()
        sdk.simulatePendingState(.connecting, handle: 701)
        sdk.simulatePendingState(.connected, handle: 701)
        replayWhileBlocked(sdk: sdk, session: session) { sdk.simulatePendingState(.ready, handle: 701) }
        XCTAssertEqual(session.latestState, .ready)
        XCTAssertTrue(sdk.findSession(handle: 701) === session)
        var received: [SessionState] = []
        for _ in 0..<3 {
            if let state = await states.next() { received.append(state) }
        }
        XCTAssertEqual(received, [.connecting, .connected, .ready])
    }

    func testTerminalArrivingDuringPendingReplayCannotBeResurrected() {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 702)
        sdk.simulatePendingState(.connecting, handle: 702)
        sdk.simulatePendingState(.connected, handle: 702)
        replayWhileBlocked(sdk: sdk, session: session) {
            sdk.simulatePendingState(.disconnected, handle: 702)
            sdk.simulatePendingState(.ready, handle: 702)
        }
        XCTAssertEqual(session.latestState, .disconnected)
        XCTAssertNil(sdk.findSession(handle: 702))
        XCTAssertEqual(sdk.pendingSessionEventCountForTesting(handle: 702), 0)
    }

    func testPendingAndConcurrentLiveScansPreserveOrderWhileAnotherSessionProgresses() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 703)
        var scans = session.scanEvents.makeAsyncIterator()
        func scan(_ text: String) {
            sdk.simulatePendingScan(handle: 703, timestampMs: 1, barcodeType: 0, textBytes: Data(text.utf8), rawBytes: Data())
        }
        scan("pending")
        replayWhileBlocked(sdk: sdk, session: session) {
            let producers = DispatchGroup()
            for producer in 0..<4 {
                producers.enter()
                DispatchQueue.global().async {
                    for index in 0..<8 { scan("\(producer):\(index)") }
                    producers.leave()
                }
            }
            XCTAssertEqual(producers.wait(timeout: .now() + 5), .success)
            let independent = sdk.registerSessionForTesting(handle: 704)
            sdk.simulatePendingState(.ready, handle: 704)
            XCTAssertEqual(independent.latestState, .ready)
        }
        var values: [String] = []
        for _ in 0..<33 {
            if let scan = await scans.next() { values.append(scan.text) }
        }
        XCTAssertEqual(values.first, "pending")
        for producer in 0..<4 {
            XCTAssertEqual(values.filter { $0.hasPrefix("\(producer):") }, (0..<8).map { "\(producer):\($0)" })
        }
        XCTAssertEqual(sdk.pendingSessionEventCountForTesting(handle: 703), 0)
    }

    func testTerminalPendingEventSurvivesLateEventFloodAndClearsResources() {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 705)
        sdk.simulatePendingState(.error, handle: 705)
        for index in 0..<64 {
            sdk.simulatePendingScan(handle: 705, timestampMs: UInt64(index), barcodeType: 0, textBytes: Data([1]), rawBytes: Data([2]))
        }
        sdk.simulatePendingState(.ready, handle: 705)
        _ = sdk.registerSessionForTesting(session)
        XCTAssertEqual(session.latestState, .error)
        XCTAssertNil(sdk.findSession(handle: 705))
        XCTAssertEqual(sdk.pendingSessionEventCountForTesting(handle: 705), 0)
        sdk.simulatePendingState(.ready, handle: 705)
        XCTAssertEqual(sdk.pendingSessionEventCountForTesting(handle: 705), 0)
    }

    func testShutdownDuringDeliveryDiscardsReplayAndPreventsTerminalStateRegression() {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 706)
        sdk.simulatePendingState(.connecting, handle: 706)
        sdk.simulatePendingState(.ready, handle: 706)
        replayWhileBlocked(sdk: sdk, session: session) { sdk.terminateSessionsForSdkShutdownForTesting() }
        session.onStateChanged(.ready)
        XCTAssertEqual(session.latestState, .disconnected)
        XCTAssertNil(sdk.findSession(handle: 706))
        XCTAssertEqual(sdk.pendingSessionEventCountForTesting(handle: 706), 0)
    }

    private func replayWhileBlocked(sdk: ScannerSDK, session: ScannerSession, live: () -> Void) {
        let entered = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        let finished = DispatchSemaphore(value: 0)
        let flagLock = NSLock()
        var first = true
        sdk.beforeSessionEventDeliveryForTesting = { handle in
            flagLock.lock()
            let blocks = handle == session.handle && first
            if blocks { first = false }
            flagLock.unlock()
            if blocks {
                entered.signal()
                XCTAssertEqual(release.wait(timeout: .now() + 5), .success)
            }
        }
        DispatchQueue.global().async {
            _ = sdk.registerSessionForTesting(session)
            finished.signal()
        }
        XCTAssertEqual(entered.wait(timeout: .now() + 5), .success)
        live()
        release.signal()
        XCTAssertEqual(finished.wait(timeout: .now() + 5), .success)
        sdk.beforeSessionEventDeliveryForTesting = nil
    }

    func testAvailableEmptyObjectIsSuccessfulUnconfiguredValue() throws {
        var result = makeNsdkCapabilityValueResult()
        result.value_kind = CapabilityValueKind.object.rawValue
        result.value_available = 1

        let value = try consumeCapabilityReadResult(&result, valueKind: .object)

        XCTAssertEqual(value.kind, .object)
        XCTAssertEqual(value.bytes, Data())
        assertCapabilityResultDisposed(&result)
    }

    func testConfiguredObjectPreservesNativeBytes() throws {
        let bytes: [UInt8] = [0x01, 0x31, 0x01, 0x32]
        var result = makeNsdkCapabilityValueResult()
        result.value_kind = CapabilityValueKind.object.rawValue
        result.value_available = 1
        result.value_size = UInt32(bytes.count)
        result.value_full_size = UInt32(bytes.count)
        withUnsafeMutableBytes(of: &result.value_bytes) { buffer in
            buffer.copyBytes(from: bytes)
        }

        let value = try consumeCapabilityReadResult(&result, valueKind: .object)

        XCTAssertEqual(value.kind, .object)
        XCTAssertEqual(value.bytes, Data(bytes))
        assertCapabilityResultDisposed(&result)
    }

    func testUnavailableObjectRemainsFailureAndDisposesResult() {
        var result = makeNsdkCapabilityValueResult()
        result.value_kind = CapabilityValueKind.object.rawValue
        result.value_available = 0
        result.storage_token = 43

        XCTAssertThrowsError(try consumeCapabilityReadResult(&result, valueKind: .object)) { error in
            XCTAssertEqual((error as? ScannerError)?.code, 11)
        }
        XCTAssertNotEqual(result.storage_token, 43)
        assertCapabilityResultDisposed(&result)
    }

    private func assertCapabilityResultDisposed(_ result: inout nsdk_capability_value_result_t) {
        var length: UInt32 = 0
        XCTAssertEqual(
            nsdk_capability_value_result_copy_full_value_bytes(&result, nil, 0, &length),
            nsdk_error_t(NSDK_ERROR_INVALID_ARGUMENT)
        )
    }

    func testDiscoveryBurstPreservesEveryDeviceForSlowConsumer() async {
        // Exercise the same unbounded hub policy as discovery without native hardware.
        let hub = StreamHub<Int>(capacity: nil)
        let buffered = hub.makeStream()
        for value in 0..<180 { hub.yield(value) }
        hub.finish()
        var values: [Int] = []
        for await value in buffered { values.append(value) }
        XCTAssertEqual(values, Array(0..<180))
    }

    func testDiscoveryV2CopiesBorrowedAdvertisementBytes() {
        var payload: [UInt8] = [0x00, 0xff, 0x80]
        let copied: DiscoveredDevice = "Scanner local".withCString { name in
            "0000180f-0000-1000-8000-00805f9b34fb".withCString { uuid in
                payload.withUnsafeBufferPointer { bytes in
                    var manufacturer = nsdk_ble_manufacturer_data_t()
                    manufacturer.company_id = 0x1234
                    manufacturer.data = bytes.baseAddress
                    manufacturer.size = UInt32(bytes.count)
                    var service = nsdk_ble_service_data_t()
                    service.service_uuid = uuid
                    service.data = bytes.baseAddress
                    service.size = UInt32(bytes.count)
                    var uuidPointer: UnsafePointer<CChar>? = uuid
                    return withUnsafePointer(to: &manufacturer) { manufacturerPointer in
                        withUnsafePointer(to: &service) { servicePointer in
                            withUnsafePointer(to: &uuidPointer) { uuidArray in
                                var value = nsdk_discovered_device_v2_t()
                                value.struct_size = UInt32(MemoryLayout<nsdk_discovered_device_v2_t>.size)
                                copyCString("anonymous", into: &value.base.device_id)
                                value.base.transport = Int32(NSDK_TRANSPORT_BLE_GATT)
                                value.advertisement_name = name
                                value.service_uuids = uuidArray
                                value.service_uuid_count = 1
                                value.manufacturer_data = manufacturerPointer
                                value.manufacturer_data_count = 1
                                value.service_data = servicePointer
                                value.service_data_count = 1
                                value.connectable = -1
                                return DiscoveredDevice(cValue: value)
                            }
                        }
                    }
                }
            }
        }
        payload[0] = 42
        XCTAssertEqual(copied.name, "")
        XCTAssertEqual(copied.deviceId, "anonymous")
        XCTAssertEqual(copied.advertisementName, "Scanner local")
        XCTAssertEqual(copied.serviceUuids, ["0000180f-0000-1000-8000-00805f9b34fb"])
        XCTAssertEqual(copied.manufacturerData[0x1234], Data([0, 255, 128]))
        XCTAssertEqual(copied.serviceData[copied.serviceUuids[0]], Data([0, 255, 128]))
        XCTAssertNil(copied.connectable)
        XCTAssertNil(copied.rssi)
    }

    func testScannerErrorPreservesNativeErrorCode() {
        XCTAssertNoThrow(try nsdkCheck(0, operation: "nativeSuccess"))

        XCTAssertThrowsError(try nsdkCheck(1, operation: "readCapabilityValue")) { error in
            let scannerError = error as? ScannerError
            XCTAssertEqual(scannerError?.code, 1)
            XCTAssertEqual(scannerError?.operation, "readCapabilityValue")
        }
    }

    func testErrorStateRemovesActiveSession() {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 124)

        sdk.simulatePendingState(.error, handle: 124)

        XCTAssertNil(sdk.findSession(handle: 124))
        XCTAssertEqual(session.latestState, .error)
    }

    func testSdkShutdownTerminatesExternallyHeldSessionAndAllStreams() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 125)
        var stateIterator = session.state.makeAsyncIterator()
        var scanIterator = session.scanEvents.makeAsyncIterator()
        var overflowIterator = session.eventOverflows.makeAsyncIterator()
        var failureIterator = session.failureEvents.makeAsyncIterator()
        var initializationIterator = session.initializationStages.makeAsyncIterator()
        var traceIterator = session.commandTraces.makeAsyncIterator()

        sdk.terminateSessionsForSdkShutdownForTesting()

        let state = await stateIterator.next()
        let stateEnd = await stateIterator.next()
        let scanEnd = await scanIterator.next()
        let overflowEnd = await overflowIterator.next()
        let failureEnd = await failureIterator.next()
        let initializationEnd = await initializationIterator.next()
        let traceEnd = await traceIterator.next()

        XCTAssertEqual(state, .disconnected)
        XCTAssertNil(stateEnd)
        XCTAssertNil(scanEnd)
        XCTAssertNil(overflowEnd)
        XCTAssertNil(failureEnd)
        XCTAssertNil(initializationEnd)
        XCTAssertNil(traceEnd)
        XCTAssertEqual(session.latestState, .disconnected)
        XCTAssertNil(sdk.findSession(handle: 125))
        let disconnectSynchronously: () throws -> Void = { try session.disconnect() }
        XCTAssertThrowsError(try disconnectSynchronously())

        var lateStateIterator = session.state.makeAsyncIterator()
        var lateScanIterator = session.scanEvents.makeAsyncIterator()
        var lateOverflowIterator = session.eventOverflows.makeAsyncIterator()
        var lateFailureIterator = session.failureEvents.makeAsyncIterator()
        var lateInitializationIterator = session.initializationStages.makeAsyncIterator()
        var lateTraceIterator = session.commandTraces.makeAsyncIterator()

        let lateState = await lateStateIterator.next()
        let lateScan = await lateScanIterator.next()
        let lateOverflow = await lateOverflowIterator.next()
        let lateFailure = await lateFailureIterator.next()
        let lateInitialization = await lateInitializationIterator.next()
        let lateTrace = await lateTraceIterator.next()

        XCTAssertNil(lateState)
        XCTAssertNil(lateScan)
        XCTAssertNil(lateOverflow)
        XCTAssertNil(lateFailure)
        XCTAssertNil(lateInitialization)
        XCTAssertNil(lateTrace)
    }

    func testScanTextCharsetIsExplicitAndPreservesSourceBytes() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 126)
        XCTAssertEqual(session.getScanTextCharset(), .utf8)

        session.setScanTextCharset(.gbk)
        var iterator = session.scanEvents.makeAsyncIterator()
        let textBytes = Data([0xD6, 0xD0, 0xCE, 0xC4])
        let rawBytes = textBytes + Data([0x0D])
        sdk.simulatePendingScan(
            handle: 126,
            timestampMs: 789,
            barcodeType: 12,
            textBytes: textBytes,
            rawBytes: rawBytes
        )

        let event = await iterator.next()
        XCTAssertEqual(session.getScanTextCharset(), .gbk)
        XCTAssertEqual(event?.text, "中文")
        XCTAssertEqual(event?.textBytes, textBytes)
        XCTAssertEqual(event?.rawBytes, rawBytes)

        let deviceCharsetRead = CapabilityValue.asciiText("Auto")
        XCTAssertEqual(deviceCharsetRead.textValue, "Auto")
        XCTAssertEqual(session.getScanTextCharset(), .gbk)
    }

    func testPermissionDeniedDiscoveryFailureHasStableLabel() {
        let label = DiscoveryFailureCode.blePermissionDenied.localizedLabel
        XCTAssertEqual(label.localizationKey, "nsdk.discovery_failure_code.permission_denied")
        XCTAssertEqual(label.fallbackDisplayName, "Bluetooth permission denied")
    }

    func testDeviceCharsetKeepsProtocolValueWhileNormalizingDisplayLabel() {
        XCTAssertEqual(DeviceCharset.utf8Txt.rawValue, "UTF8 (Txt)")
        XCTAssertEqual(DeviceCharset.utf8Txt.displayName, "UTF-8 (Text)")
        XCTAssertEqual(DeviceCharset.utf8Txt.localizedLabel.fallbackDisplayName, "UTF-8 (Text)")
        XCTAssertEqual(DeviceCharset.utf8Word.rawValue, "UTF8 (Word)")
        XCTAssertEqual(DeviceCharset.utf8Word.displayName, "UTF-8 (Word)")
    }

    func testProductApiSurfaceCompiles() {
        let refreshInfo: (ScannerSession) throws -> ScannerInfo = { try $0.refreshInfo() }
        let initializeSession: (ScannerSession) throws -> SessionInitializationResult = {
            try $0.initialize()
        }
        let getCachedInfo: (ScannerSession) throws -> ScannerInfo = { try $0.getCachedInfo() }
        let getCachedBatteryInfo: (ScannerSession) throws -> BatteryInfo? = {
            try $0.getCachedBatteryInfo()
        }
        let resolvedModelKey: (ScannerSession) throws -> String = { try $0.getResolvedModelKey() }
        let publicCapabilitySummary: (ScannerSession) throws -> DeviceCapabilitySummary = {
            try $0.getDeviceCapabilitySummary()
        }
        let sessionCapabilityDomains: (ScannerSession) throws -> [CapabilityDomain] = {
            try $0.getCapabilityDomains()
        }
        let sessionCapabilityEntries: (ScannerSession) throws -> [CapabilityEntry] = {
            try $0.getCapabilityEntries()
        }
        let sessionCapabilityLookup: (ScannerSession) throws -> CapabilityEntry? = {
            try $0.findCapabilityEntry("setting.QrCodeEnable")
        }
        let readCapabilityValue: (ScannerSession) throws -> CapabilityValue = {
            try $0.readCapabilityValue("setting.QrCodeEnable")
        }
        let writeCapabilityValue: (ScannerSession) throws -> CommandResponse = {
            try $0.writeCapabilityValue("setting.QrCodeEnable", value: .boolean(true))
        }
        let operationSupport: (ScannerSession) throws -> SessionOperationSupport = {
            try $0.getOperationSupport()
        }
        let connectDevice: (ScannerSDK, DiscoveredDevice) async throws -> ScannerSession = { sdk, device in
            try await sdk.connectReady(device)
        }
        let getPublicProfile: (ScannerSDK) throws -> DeviceModelProfile? = {
            $0.getDeviceModelProfile("CS7501")
        }
        let getSupportedDeviceModels: (ScannerSDK) throws -> [SupportedDeviceModel] = {
            try $0.getSupportedDeviceModels(transport: .bleGatt)
        }
        let getDataRuleKindLabel: (ScannerSDK) throws -> DataRuleKindLabel = {
            try $0.getDataRuleKindLabel(.prefix)
        }
        let exportNativeLogs: (ScannerSDK) throws -> LogPackage = {
            try $0.exportNativeLogs(LogExportRequest())
        }
        let getCapabilityDomains: (ScannerSDK) throws -> [CapabilityDomain] = {
            try $0.getCapabilityDomains(modelKey: "NT-91", transport: .bleGatt)
        }
        let getCapabilityEntries: (ScannerSDK) throws -> [CapabilityEntry] = {
            try $0.getCapabilityEntries(modelKey: "NT-91", transport: .bleGatt)
        }
        let findCapabilityEntry: (ScannerSDK) throws -> CapabilityEntry? = {
            try $0.findCapabilityEntry(modelKey: "NT-91", transport: .bleGatt, entryKey: "setting.QrCodeEnable")
        }
        let setBluetoothName: (ScannerSession) throws -> CommandResponse = {
            try $0.setBluetoothName("CS7501-A01")
        }
        let setTimestamp: (ScannerSession) throws -> CommandResponse = {
            try $0.setTimestamp(Date(timeIntervalSince1970: 1_718_179_200))
        }
        let setAckBeepEnabled: (ScannerSession) throws -> CommandResponse = {
            try $0.setAckBeepEnabled(true)
        }
        let setVibrationEnabled: (ScannerSession) throws -> CommandResponse = {
            try $0.setVibrationEnabled(false)
        }
        let applyDataRule: (ScannerSession) throws -> CommandResponse = {
            try $0.applyDataRule(.prefix("A"))
        }
        let triggerScan: (ScannerSession) throws -> Void = {
            try $0.triggerScan()
        }

        XCTAssertNotNil(refreshInfo)
        XCTAssertNotNil(initializeSession)
        XCTAssertNotNil(getCachedInfo)
        XCTAssertNotNil(getCachedBatteryInfo)
        XCTAssertNotNil(resolvedModelKey)
        XCTAssertNotNil(publicCapabilitySummary)
        XCTAssertNotNil(sessionCapabilityDomains)
        XCTAssertNotNil(sessionCapabilityEntries)
        XCTAssertNotNil(sessionCapabilityLookup)
        XCTAssertNotNil(readCapabilityValue)
        XCTAssertNotNil(writeCapabilityValue)
        XCTAssertNotNil(operationSupport)
        XCTAssertNotNil(connectDevice)
        XCTAssertNotNil(getPublicProfile)
        XCTAssertNotNil(getSupportedDeviceModels)
        XCTAssertNotNil(getDataRuleKindLabel)
        XCTAssertNotNil(exportNativeLogs)
        XCTAssertNotNil(getCapabilityDomains)
        XCTAssertNotNil(getCapabilityEntries)
        XCTAssertNotNil(findCapabilityEntry)
        XCTAssertNotNil(setBluetoothName)
        XCTAssertNotNil(setTimestamp)
        XCTAssertNotNil(setAckBeepEnabled)
        XCTAssertNotNil(setVibrationEnabled)
        XCTAssertNotNil(applyDataRule)
        XCTAssertNotNil(triggerScan)
    }

    func testPublicCommandResponseDoesNotExposeModuleFields() {
        let response = CommandResponse(
            textBytes: Data("OK".utf8),
            textFullSize: 2,
            rawBytes: Data([0x06]),
            acknowledged: true,
            recordCount: 0,
            recordBytes: [],
            recordsComplete: true
        )

        XCTAssertEqual(response.text, "OK")
        XCTAssertEqual(response.rawHex, "06")
        XCTAssertTrue(response.acknowledged)
    }

    func testModelKeyPublicSummaryUsesStringIdentity() {
        let summary = DeviceCapabilitySummary(
            modelKey: "CS7501",
            modelName: "",
            supportsScanControl: true,
            supportsDeviceCommands: true,
            supportsSettingsRead: true,
            supportsSettingsWrite: true,
            supportsDataRules: true,
            supportsBattery: true,
            supportStatus: .verified
        )

        XCTAssertEqual(summary.displayModelName, "CS7501")
        XCTAssertTrue(summary.displaySummary.contains("CS7501"))
    }

    func testCommandTraceModelExposesCommandDetails() {
        let trace = CommandTrace(
            sessionHandle: 4,
            timestampMs: 1,
            durationMs: 2,
            transportType: .bleGatt,
            resolvedModelKey: "CS7501",
            kind: .capabilityRead,
            errorCode: 0,
            acknowledged: true,
            requestAvailable: true,
            responseAvailable: true,
            operation: "readCapabilityValue",
            entryKey: "setting.QrCodeEnable",
            semanticKey: "QrCodeEnable",
            domainKey: "symbology",
            requestText: "%QR#?",
            requestHex: "255152233F",
            responseText: "1",
            responseHex: "31"
        )

        XCTAssertEqual(trace.operation, "readCapabilityValue")
        XCTAssertEqual(trace.entryKey, "setting.QrCodeEnable")
        XCTAssertEqual(trace.semanticKey, "QrCodeEnable")
        XCTAssertEqual(trace.requestHex, "255152233F")
        XCTAssertEqual(trace.responseText, "1")
    }

    func testExportNativeLogsWritesRedactedZipPackage() throws {
        let sdk = ScannerSDK.makeTestingInstance()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("scanner-sdk-log-export-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        sdk.emitDebug("BLE scan started deviceId=AA:BB:CC:DD:EE:FF hex=01 02 03")
        let package = try sdk.exportNativeLogs(
            LogExportRequest(directory: directory)
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: package.path))
        XCTAssertTrue(package.redacted)
        XCTAssertEqual(package.eventCount, 1)
        let data = try Data(contentsOf: URL(fileURLWithPath: package.path))
        XCTAssertEqual(Array(data.prefix(4)), [0x50, 0x4b, 0x03, 0x04])
        let archiveText = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(archiveText.contains("manifest.json"))
        XCTAssertTrue(archiveText.contains("events.jsonl"))
        XCTAssertTrue(archiveText.contains("summary.txt"))
        XCTAssertFalse(archiveText.contains("AA:BB:CC:DD:EE:FF"))
        XCTAssertFalse(archiveText.contains("hex=01 02 03"))
    }

    func testExportNativeLogsCanIncludeUnredactedScanPayload() throws {
        let sdk = ScannerSDK.makeTestingInstance()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("scanner-sdk-log-export-payload-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        sdk.simulatePendingScan(
            handle: 99,
            timestampMs: 1_782_784_000_000,
            barcodeType: 12,
            textBytes: Data("SKU-C740-001".utf8),
            rawBytes: Data([0x53, 0x4b, 0x55, 0x0d])
        )
        let package = try sdk.exportNativeLogs(
            LogExportRequest(
                includeScanPayload: true,
                redactScanPayload: false,
                directory: directory
            )
        )

        XCTAssertFalse(package.redacted)
        let data = try Data(contentsOf: URL(fileURLWithPath: package.path))
        let archiveText = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(archiveText.contains("scan_payload_unredacted.jsonl"))
        XCTAssertTrue(archiveText.contains("SKU-C740-001"))
        XCTAssertTrue(archiveText.contains("unredacted_scan_payload_requested"))
    }

    func testPublicCapabilitySummaryHasNoModuleFields() {
        let summary = DeviceCapabilitySummary(
            modelKey: "NT-91",
            modelName: "NT-91",
            supportsScanControl: true,
            supportsDeviceCommands: true,
            supportsSettingsRead: true,
            supportsSettingsWrite: true,
            supportsDataRules: true,
            supportsBattery: true,
            supportStatus: .verified
        )

        XCTAssertEqual(summary.displayModelName, "NT-91")
        XCTAssertTrue(summary.supportsSettingsRead)
        XCTAssertTrue(summary.supportsSettingsWrite)
    }

    func testSessionOperationSupportUsesSemanticFields() {
        let summary = SessionOperationSupport(
            supportsRefreshInfo: false,
            supportsInitializeSession: false,
            supportsGetBatteryInfo: false,
            supportsApplyDataRule: false,
            supportsTriggerScan: false,
            supportsSetAckBeepEnabled: false,
            supportsSetVibrationEnabled: false
        )

        XCTAssertFalse(summary.supportsRefreshInfo)
        XCTAssertFalse(summary.supportsTriggerScan)
        XCTAssertTrue(summary.displaySummary.contains("refreshInfo=false"))
        XCTAssertFalse(summary.displaySummary.contains("basicDeviceCommands"))
        XCTAssertFalse(summary.displaySummary.contains("dataRuleCommands"))
    }

    func testDataRulePayloadsMatchPublicShape() throws {
        let prefix = try DataRule.prefix("AB").cPayload
        XCTAssertEqual(prefix.kind, .prefix)
        XCTAssertEqual(prefix.primary, Data([0x41, 0x42]))
        XCTAssertTrue(prefix.secondary.isEmpty)

        let hideMiddle = try DataRule.hideMiddle(start: 2, length: 3).cPayload
        XCTAssertEqual(hideMiddle.kind, .hideMiddle)
        XCTAssertEqual(hideMiddle.primary, Data([0x02]))
        XCTAssertEqual(hideMiddle.secondary, Data([0x03]))

        let replace = try DataRule.replace(source: Data([0x31]), target: Data([0x32])).cPayload
        XCTAssertEqual(replace.kind, .replace)
        XCTAssertEqual(replace.primary, Data([0x31]))
        XCTAssertEqual(replace.secondary, Data([0x32]))

        let asciiFallback = try DataRule.prefix("A中").cPayload
        XCTAssertEqual(asciiFallback.primary, Data([0x41, 0x3F]))
    }
}
