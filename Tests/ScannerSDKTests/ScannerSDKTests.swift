import XCTest
import CNSDK
@testable import ScannerSDK

final class ScannerSDKTests: XCTestCase {
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
