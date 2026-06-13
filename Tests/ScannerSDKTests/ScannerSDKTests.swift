import XCTest
import CNSDK
@testable import ScannerSDK

final class ScannerSDKTests: XCTestCase {
    private func copyCString(_ text: String, into buffer: inout some Any) {
        withUnsafeMutableBytes(of: &buffer) { rawBuffer in
            rawBuffer.initializeMemory(as: UInt8.self, repeating: 0)
            let bytes = Array(text.utf8.prefix(max(0, rawBuffer.count - 1)))
            rawBuffer.copyBytes(from: bytes)
        }
    }

    func testScannerErrorPreservesNativeErrorCode() {
        XCTAssertNoThrow(try nsdkCheck(0, operation: "nativeSuccess"))

        XCTAssertThrowsError(try nsdkCheck(1, operation: "executeModuleRawFrame")) { error in
            let scannerError = error as? ScannerError
            XCTAssertEqual(scannerError?.code, 1)
            XCTAssertEqual(scannerError?.operation, "executeModuleRawFrame")
        }

        XCTAssertThrowsError(try nsdkCheck(3, operation: "triggerScan")) { error in
            let scannerError = error as? ScannerError
            XCTAssertEqual(scannerError?.code, 3)
            XCTAssertEqual(scannerError?.operation, "triggerScan")
        }
    }

    func testQueryApiSurfaceCompilesWithoutConfigQueryMethods() {
        let refreshInfo: (ScannerSession) throws -> ScannerInfo = { try $0.refreshInfo() }
        let initializeSession: (ScannerSession) throws -> SessionInitializationResult = {
            try $0.initializeSession()
        }
        let getCachedInfo: (ScannerSession) throws -> ScannerInfo = { try $0.getCachedInfo() }
        let getCachedBatteryInfo: (ScannerSession) throws -> BatteryInfo? = {
            try $0.getCachedBatteryInfo()
        }
        let resolvedModelId: (ScannerSession) throws -> DeviceModelId = { try $0.getResolvedModelId() }
        let capabilitySummary: (ScannerSession) throws -> DeviceCapabilitySummary = { try $0.getDeviceCapabilitySummary() }
        let operationSupport: (ScannerSession) throws -> SessionOperationSupportSummary = {
            try $0.getOperationSupportSummary()
        }
        let defaultModuleProbe: (ScannerSession) throws -> Bool = {
            try $0.canExecuteDefaultModuleCommandProbe(family: .nt212x)
        }
        let connectDevice: (ScannerSDK, DiscoveredDevice) async throws -> ScannerSession = { sdk, device in
            try await sdk.connectReady(device)
        }
        let getCommandDescriptor: (ScannerSDK) throws -> CommandDescriptor = {
            try $0.getCommandDescriptor(.getInfo)
        }
        let getBasicDescriptor: (ScannerSDK) throws -> CommandDescriptor = {
            try $0.getBasicDeviceCommandDescriptor(.getVersion)
        }
        let getCommandCodeLabel: (ScannerSDK) throws -> CommandCodeLabel = {
            try $0.getCommandCodeLabel(.getInfo)
        }
        let getBasicCommandLabel: (ScannerSDK) throws -> BasicDeviceCommandLabel = {
            try $0.getBasicDeviceCommandLabel(.getVersion)
        }
        let getDataRuleKindLabel: (ScannerSDK) throws -> DataRuleKindLabel = {
            try $0.getDataRuleKindLabel(.prefix)
        }
        let getDeviceModelName: (ScannerSDK) throws -> String = {
            try $0.getDeviceModelName(.cs7501)
        }
        let getMasterDescriptor: (ScannerSDK) throws -> CommandDescriptor = {
            try $0.getMasterCommandDescriptor(.powerOff)
        }
        let getMasterMetadata: (ScannerSDK) throws -> MasterCommandMetadata = {
            try $0.getMasterCommandMetadata(.powerOff)
        }
        let getMasterCategoryLabel: (ScannerSDK) throws -> MasterCommandCategoryLabel = {
            try $0.getMasterCommandCategoryLabel(.wired)
        }
        let getMasterSectionLabel: (ScannerSDK) throws -> MasterCommandSectionLabel = {
            try $0.getMasterCommandSectionLabel(.bluetoothTransport)
        }
        let isModuleCommandDangerous: (ScannerSDK) throws -> Bool = {
            try $0.isModuleCommandDangerous(.saveSettings)
        }
        let moduleCommandLabel: (ScannerSDK) throws -> ModuleCommandKindLabel = {
            try $0.getModuleCommandKindLabel(.saveSettings)
        }
        let moduleActionPresetLabel: (ScannerSDK) throws -> ModuleActionPresetLabel? = {
            try $0.getModuleActionPresetLabel(actionID: "nt280h_scan_auto")
        }
        let moduleTestRecommendations: (ScannerSDK) throws -> [ModuleTestRecommendation] = {
            try $0.getModuleTestRecommendations(family: .nt212x)
        }
        let nt212xDefinitions: (ScannerSDK) throws -> [Nt212xParameterDefinition] = {
            try $0.getNt212xParameterDefinitions()
        }
        let nt280hDefinitions: (ScannerSDK) throws -> [Nt280hParameterDefinition] = {
            try $0.getNt280hParameterDefinitions()
        }
        let se4750Definitions: (ScannerSDK) throws -> [Se4750ParameterDefinition] = {
            try $0.getSe4750ParameterDefinitions()
        }
        let ntc06hDefinitions: (ScannerSDK) throws -> [Ntc06hSettingDefinition] = {
            try $0.getNtc06hSettingDefinitions()
        }
        let quickValues: (ScannerSDK) throws -> [ModuleParameterQuickValue] = {
            try $0.getModuleParameterQuickValues(
                family: .se4750,
                parameterID: Se4750Parameters.decodeSessionTimeout
            )
        }
        let numericSpec: (ScannerSDK) throws -> ModuleParameterNumericInputSpec? = {
            try $0.getModuleParameterNumericInputSpec(
                family: .nt212x,
                parameterID: UInt32(Nt212xParameters.param12)
            )
        }
        let booleanPair: (ScannerSDK) throws -> ModuleParameterBooleanPayloadPair? = {
            try $0.getModuleParameterBooleanPayloadPair(
                family: .nt280h,
                parameterID: UInt32(Nt280hParameters.qrCodeEnable)
            )
        }
        let titleLabel: (ScannerSDK) throws -> ModuleParameterTitleLabel? = {
            try $0.getModuleParameterTitleLabel(
                family: .se4750,
                parameterID: Se4750Parameters.beepAfterGoodDecode,
                aliasName: "",
                displayName: "Good Read Beep"
            )
        }
        let kindLabel: (ScannerSDK) throws -> ModuleParameterKindLabel? = {
            try $0.getModuleParameterKindLabel(.bool)
        }
        let taxonomyEntries: (ScannerSDK) throws -> [ModuleTaxonomyEntry] = {
            try $0.getModuleTaxonomyEntries(kind: .group)
        }
        let taxonomyGroupKeys: ([Nt212xParameterDefinition]) -> [String] = {
            ModuleTaxonomyGrouping.groupKeys($0)
        }
        let taxonomyDomainGroups: ([Nt212xParameterDefinition]) -> [ModuleTaxonomyDomainGroup<Nt212xParameterDefinition>] = {
            ModuleTaxonomyGrouping.domainGroups($0)
        }
        let moduleCommand: (ScannerSession) throws -> CommandResponse = {
            try $0.executeModuleCommand(
                family: .nt212x,
                kind: .writeParameter,
                parameterID: UInt32(Nt212xParameters.paramF025),
                payload: Data([0x01])
            )
        }
        let setBluetoothName: (ScannerSession) throws -> CommandResponse = {
            try $0.setBluetoothName("CS7501-A01")
        }
        let setTimestamp: (ScannerSession) throws -> CommandResponse = {
            try $0.setTimestamp(Date(timeIntervalSince1970: 1_718_179_200))
        }
        let moduleRawFrame: (ScannerSession) throws -> CommandResponse = {
            try $0.executeModuleRawFrame(family: .nt212x, frame: Data([0x04, 0xE4, 0x04, 0x00, 0xFF]))
        }

        XCTAssertNotNil(refreshInfo)
        XCTAssertNotNil(initializeSession)
        XCTAssertNotNil(getCachedInfo)
        XCTAssertNotNil(getCachedBatteryInfo)
        XCTAssertNotNil(resolvedModelId)
        XCTAssertNotNil(capabilitySummary)
        XCTAssertNotNil(operationSupport)
        XCTAssertNotNil(defaultModuleProbe)
        XCTAssertNotNil(connectDevice)
        XCTAssertNotNil(getCommandDescriptor)
        XCTAssertNotNil(getBasicDescriptor)
        XCTAssertNotNil(getCommandCodeLabel)
        XCTAssertNotNil(getBasicCommandLabel)
        XCTAssertNotNil(getDataRuleKindLabel)
        XCTAssertNotNil(getDeviceModelName)
        XCTAssertNotNil(getMasterDescriptor)
        XCTAssertNotNil(getMasterMetadata)
        XCTAssertNotNil(getMasterCategoryLabel)
        XCTAssertNotNil(getMasterSectionLabel)
        XCTAssertNotNil(isModuleCommandDangerous)
        XCTAssertNotNil(moduleCommandLabel)
        XCTAssertNotNil(moduleActionPresetLabel)
        XCTAssertNotNil(moduleTestRecommendations)
        XCTAssertNotNil(nt212xDefinitions)
        XCTAssertNotNil(nt280hDefinitions)
        XCTAssertNotNil(se4750Definitions)
        XCTAssertNotNil(ntc06hDefinitions)
        XCTAssertNotNil(quickValues)
        XCTAssertNotNil(numericSpec)
        XCTAssertNotNil(booleanPair)
        XCTAssertNotNil(titleLabel)
        XCTAssertNotNil(kindLabel)
        XCTAssertNotNil(taxonomyEntries)
        XCTAssertNotNil(taxonomyGroupKeys)
        XCTAssertNotNil(taxonomyDomainGroups)
        XCTAssertNotNil(moduleCommand)
        XCTAssertNotNil(setBluetoothName)
        XCTAssertNotNil(setTimestamp)
        XCTAssertNotNil(moduleRawFrame)
        XCTAssertEqual(ProtocolChannelKind.scannerMaster.rawValue, 0)
        XCTAssertEqual(ModuleFamily.unknown.rawValue, 0)
        XCTAssertEqual(ProtocolChannelKind.modulePassthrough.rawValue, 1)
        XCTAssertEqual(ModuleFamily.nt212x.rawValue, 3)
        XCTAssertEqual(ModuleFamily.se4750.rawValue, 4)
        XCTAssertEqual(ModuleCommandKind.writeParameter.rawValue, 5)
        XCTAssertEqual(ModuleCommandKind.saveSettings.rawValue, 7)
        XCTAssertEqual(ModuleCommandKind.ack.rawValue, 14)
        XCTAssertEqual(ModuleCommandKind.nak.rawValue, 15)
        XCTAssertEqual(ModuleCommandKind.capabilitiesRequest.rawValue, 16)
        XCTAssertEqual(ModuleCommandKind.changeAllCodeTypes.rawValue, 21)
        XCTAssertEqual(ModuleCommandKind.beep.rawValue, 22)
        XCTAssertEqual(ModuleCommandKind.pagerMotorActivation.rawValue, 23)
        XCTAssertEqual(CommandCode.getInfo.rawValue, 0x0001)
        XCTAssertEqual(CommandCode.beep.rawValue, 0x0006)
        XCTAssertEqual(CommandCode.vibrateOn.rawValue, 0x0008)
        XCTAssertEqual(MasterCommandCategory.power.rawValue, 1)
        XCTAssertEqual(MasterCommandSection.decoderModule.rawValue, 23)
        XCTAssertEqual(ModuleParameterNumericInputKind.tenthsSeconds.rawValue, 1)
        XCTAssertEqual(ModuleParameterNumericInputKind.uint8Decimal.rawValue, 2)
        XCTAssertEqual(ModuleParameterNumericInputKind.uint16Milliseconds.rawValue, 3)
        XCTAssertEqual(ModuleTaxonomyKind.group.rawValue, 1)
        XCTAssertEqual(ModuleTaxonomyKind.section.rawValue, 4)
    }

    func testDeviceCapabilitySummaryKeepsStructuredFieldsStable() {
        let summary = DeviceCapabilitySummary(
            modelId: .nt91,
            modelName: "NT-91",
            defaultCommandSet: .moduleOnly,
            formFactor: .singleModule,
            moduleFamily: .nt212x,
            supportsBasicDeviceCommands: false,
            supportsMasterCommands: false,
            supportsNativeModuleCommands: true,
            supportsModuleCommandBridge: false,
            supportsModuleCommands: true,
            supportsScannerMaster: false,
            supportsModulePassthrough: true,
            supportStatus: .verified
        )

        XCTAssertEqual(summary.displayModelName, "NT-91")
        XCTAssertEqual(summary.modelId, .nt91)
        XCTAssertEqual(summary.supportStatus, .verified)
        XCTAssertTrue(summary.displaySummary.contains("moduleOnly"))
        XCTAssertTrue(summary.displaySummary.contains("nativeModule=true"))
    }

    func testDeviceModelNameExposesCoreVocabulary() throws {
        XCTAssertEqual(try ScannerSDK.shared.getDeviceModelName(.cs7501), "CS7501")
        XCTAssertEqual(try ScannerSDK.shared.getDeviceModelName(.nt91), "NT-91")
        XCTAssertEqual(try ScannerSDK.shared.getDeviceModelName(.nt1228bc), "NT-1228BC")
    }

    func testSessionOperationSupportSummaryKeepsStructuredFieldsStable() {
        let summary = SessionOperationSupportSummary(
            supportsRefreshInfo: false,
            supportsInitializeSession: false,
            supportsGetBatteryInfo: false,
            supportsExecuteBasicDeviceCommands: false,
            supportsExecuteTextCommands: false,
            supportsExecuteDataRuleCommands: false,
            supportsDefaultModuleCommandProbe: false,
            supportsTriggerScan: false,
            supportsBeep: false,
            supportsDisableAckBeep: false,
            supportsVibrateOn: false,
            supportsVibrateOff: false
        )

        XCTAssertFalse(summary.supportsRefreshInfo)
        XCTAssertFalse(summary.supportsTriggerScan)
        XCTAssertTrue(summary.displaySummary.contains("refreshInfo=false"))
        XCTAssertTrue(summary.displaySummary.contains("defaultModuleProbe=false"))
        XCTAssertTrue(summary.displaySummary.contains("vibrateOff=false"))
    }

    func testCommandDescriptorModelKeepsStructuredFieldsStable() {
        let descriptor = CommandDescriptor(text: "%ACKBEEP#1", isDangerous: true)
        let metadata = MasterCommandMetadata(category: .power, section: .powerSleep)
        let commandLabel = CommandCodeLabel(localizationKey: "nsdk.command_code.get_info", fallbackDisplayName: "Refresh Info")
        let basicLabel = BasicDeviceCommandLabel(localizationKey: "nsdk.basic_device_command.get_version", fallbackDisplayName: "Get Version")
        let dataRuleLabel = DataRuleKindLabel(localizationKey: "nsdk.data_rule_command_kind.prefix", fallbackDisplayName: "Prefix")

        XCTAssertEqual(descriptor.text, "%ACKBEEP#1")
        XCTAssertTrue(descriptor.isDangerous)
        XCTAssertEqual(metadata.category, .power)
        XCTAssertEqual(metadata.section, .powerSleep)
        XCTAssertEqual(commandLabel.localizationKey, "nsdk.command_code.get_info")
        XCTAssertEqual(commandLabel.fallbackDisplayName, "Refresh Info")
        XCTAssertEqual(basicLabel.localizationKey, "nsdk.basic_device_command.get_version")
        XCTAssertEqual(basicLabel.fallbackDisplayName, "Get Version")
        XCTAssertEqual(dataRuleLabel.localizationKey, "nsdk.data_rule_command_kind.prefix")
        XCTAssertEqual(dataRuleLabel.fallbackDisplayName, "Prefix")
    }

    func testSessionStateLabelsExposeRuntimeMetadata() {
        XCTAssertEqual(SessionState.idle.localizedLabel.localizationKey, "nsdk.session_state.idle")
        XCTAssertEqual(SessionState.idle.localizedLabel.fallbackDisplayName, "Idle")
        XCTAssertEqual(SessionState.ready.localizedLabel.localizationKey, "nsdk.session_state.connected_ready")
        XCTAssertEqual(SessionState.ready.localizedLabel.fallbackDisplayName, "Connected, ready")
        XCTAssertEqual(SessionState.error.localizedLabel.localizationKey, "nsdk.session_state.connection_error")
        XCTAssertEqual(SessionState.error.localizedLabel.fallbackDisplayName, "Connection error")
    }

    func testProtocolChannelLabelsExposeRuntimeMetadata() {
        XCTAssertEqual(ProtocolChannelKind.scannerMaster.localizedLabel.localizationKey, "nsdk.protocol_channel_kind.scanner_master")
        XCTAssertEqual(ProtocolChannelKind.scannerMaster.localizedLabel.fallbackDisplayName, "Scanner master")
        XCTAssertEqual(ProtocolChannelKind.modulePassthrough.localizedLabel.localizationKey, "nsdk.protocol_channel_kind.module_passthrough")
        XCTAssertEqual(ProtocolChannelKind.modulePassthrough.localizedLabel.fallbackDisplayName, "Module passthrough")
    }

    func testTransportTypeLabelsExposeRuntimeMetadata() {
        XCTAssertEqual(TransportType.bleGatt.localizedLabel.localizationKey, "nsdk.transport_type.ble_gatt")
        XCTAssertEqual(TransportType.bleGatt.localizedLabel.fallbackDisplayName, "BLE GATT")
        XCTAssertEqual(TransportType.usbSerial.localizedLabel.localizationKey, "nsdk.transport_type.usb_serial")
        XCTAssertEqual(TransportType.usbSerial.localizedLabel.fallbackDisplayName, "USB Serial")
        XCTAssertEqual(TransportType.sppClassic.localizedLabel.localizationKey, "nsdk.transport_type.spp_classic")
        XCTAssertEqual(TransportType.sppClassic.localizedLabel.fallbackDisplayName, "SPP Classic")
    }

    func testDeviceCapabilityLabelsExposeRuntimeMetadata() {
        XCTAssertEqual(CommandSetKind.masterOnly.localizedLabel.localizationKey, "nsdk.command_set_kind.scanner_master")
        XCTAssertEqual(CommandSetKind.masterOnly.localizedLabel.fallbackDisplayName, "Scanner master")
        XCTAssertEqual(DeviceFormFactor.singleModule.localizedLabel.localizationKey, "nsdk.device_form_factor.single_module")
        XCTAssertEqual(DeviceFormFactor.singleModule.localizedLabel.fallbackDisplayName, "Single module")
        XCTAssertEqual(SupportStatus.verified.localizedLabel.localizationKey, "nsdk.support_status.verified")
        XCTAssertEqual(SupportStatus.verified.localizedLabel.fallbackDisplayName, "Verified")
        XCTAssertEqual(ModuleFamily.unknown.localizedLabel.localizationKey, "nsdk.module_family.unknown_module")
        XCTAssertEqual(ModuleFamily.unknown.localizedLabel.fallbackDisplayName, "Unknown module")
    }

    func testNt212xTypedHelperSurfaceCompiles() {
        let readHelper: (ScannerSession) throws -> CommandResponse = {
            try $0.readNt212xParameter(Nt212xParameterAliases.qrCodeEnable)
        }
        let writeHelper: (ScannerSession) throws -> CommandResponse = {
            try $0.writeNt212xParameter(Nt212xParameterAliases.qrCodeEnable, valueBytes: Data([0x01]))
        }
        let getQrHelper: (ScannerSession) throws -> Bool = { try $0.getQrCodeEnabled() }
        let setQrHelper: (ScannerSession) throws -> CommandResponse = { try $0.setQrCodeEnabled(true) }

        XCTAssertNotNil(readHelper)
        XCTAssertNotNil(writeHelper)
        XCTAssertNotNil(getQrHelper)
        XCTAssertNotNil(setQrHelper)
    }

    func testNt280hTypedHelperSurfaceCompiles() {
        let readHelper: (ScannerSession) throws -> CommandResponse = {
            try $0.readNt280hParameter(Nt280hParameters.qrCodeEnable)
        }
        let writeHelper: (ScannerSession) throws -> CommandResponse = {
            try $0.writeNt280hParameter(Nt280hParameters.qrCodeEnable, valueBytes: Data([0x0E]))
        }

        XCTAssertNotNil(readHelper)
        XCTAssertNotNil(writeHelper)
    }

    func testNt212xResponseHelperDecodesBooleanParameter() {
        let response = CommandResponse(
            textBytes: Data(),
            rawBytes: Data([0x08, 0xC6, 0x00, 0x00, 0xFF, 0xF0, 0x25, 0x01, 0xFD, 0x1D]),
            acknowledged: false,
            recordCount: 0,
            recordBytes: [],
            recordsComplete: true,
            moduleParameterID: Int(Nt212xParameterAliases.qrCodeEnable),
            moduleParameterValueBytes: Data([0x01]),
            moduleParameterValueAvailable: true
        )

        XCTAssertTrue(response.nt212xBooleanParameterValue(parameterID: Nt212xParameterAliases.qrCodeEnable))
    }

    func testNt212xAliasesExposeLabels() {
        XCTAssertEqual(Nt212xParameterAliases.getLabel(parameterID: Nt212xParameterAliases.qrCodeEnable), "QrCodeEnable")
    }

    func testNt212xCatalogExposesDefinitions() throws {
        let runtimeDefinitions = try ScannerSDK.shared.getNt212xParameterDefinitions()
        let runtimeQrCode = try ScannerSDK.shared.findNt212xParameter(byID: Nt212xParameterAliases.qrCodeEnable)
        let qrCode = Nt212xParameterCatalog.findByID(Nt212xParameterAliases.qrCodeEnable)

        XCTAssertEqual(Nt212xParameterCatalog.all.count, runtimeDefinitions.count)
        XCTAssertEqual(qrCode?.key, "F0_25")
        XCTAssertEqual(qrCode?.aliasName, "QrCodeEnable")
        XCTAssertEqual(qrCode?.displayName, "QR Code Switch")
        XCTAssertEqual(qrCode?.key, runtimeQrCode?.key)
        XCTAssertEqual(qrCode?.aliasName, runtimeQrCode?.aliasName)
    }

    func testNt280hResponseHelperDecodesBooleanParameter() {
        let response = CommandResponse(
            textBytes: Data(),
            rawBytes: Data([0x05, 0x52, 0xDB, 0x01, 0x0E, 0x00, 0x00]),
            acknowledged: false,
            recordCount: 0,
            recordBytes: [],
            recordsComplete: true,
            moduleParameterID: Int(Nt280hParameters.qrCodeEnable),
            moduleParameterValueBytes: Data([0x0E]),
            moduleParameterValueAvailable: true
        )

        XCTAssertTrue(response.nt280hBooleanParameterValue(parameterID: Nt280hParameters.qrCodeEnable))
    }

    func testNt280hCatalogExposesDefinitions() throws {
        let runtimeDefinitions = try ScannerSDK.shared.getNt280hParameterDefinitions()
        let runtimeQrCode = try ScannerSDK.shared.findNt280hParameter(byID: Nt280hParameters.qrCodeEnable)
        let qrCode = Nt280hParameterCatalog.findByID(Nt280hParameters.qrCodeEnable)

        XCTAssertEqual(Nt280hParameterCatalog.all.count, runtimeDefinitions.count)
        XCTAssertEqual(qrCode?.key, "DB_01")
        XCTAssertEqual(qrCode?.semanticName, "QrCodeEnable")
        XCTAssertEqual(qrCode?.familyKey, "qr_code")
        XCTAssertEqual(qrCode?.sectionKey, "basic")
        XCTAssertEqual(qrCode?.key, runtimeQrCode?.key)
        XCTAssertEqual(qrCode?.semanticName, runtimeQrCode?.semanticName)
    }

    func testSe4750CatalogExposesDefinitions() throws {
        let runtimeDefinitions = try ScannerSDK.shared.getSe4750ParameterDefinitions()
        let runtimeDefinition = try ScannerSDK.shared.findSe4750Parameter(byID: Se4750Parameters.decodeSessionTimeout)
        let definition = Se4750ParameterCatalog.findByID(Se4750Parameters.decodeSessionTimeout)

        XCTAssertEqual(Se4750ParameterCatalog.all.count, runtimeDefinitions.count)
        XCTAssertEqual(definition?.key, "88")
        XCTAssertEqual(definition?.semanticName, "DecodeSessionTimeout")
        XCTAssertEqual(definition?.key, runtimeDefinition?.key)
        XCTAssertEqual(definition?.semanticName, runtimeDefinition?.semanticName)
    }

    func testSe4750ResponseHelperDecodesThreeByteParameter() {
        let response = CommandResponse(
            textBytes: Data(),
            rawBytes: Data([0x09, 0xC6, 0x00, 0x00, 0xFF, 0xF8, 0x07, 0x59, 0x01, 0xFC, 0xD9]),
            acknowledged: false,
            recordCount: 0,
            recordBytes: [],
            recordsComplete: true,
            moduleParameterID: Int(Se4750Parameters.transmitEAN8CheckDigit),
            moduleParameterValueBytes: Data([0x01]),
            moduleParameterValueAvailable: true
        )

        XCTAssertTrue(response.se4750BooleanParameterValue(parameterID: Se4750Parameters.transmitEAN8CheckDigit))
    }

    func testRuntimeParameterDefinitionsExposeCatalogMetadata() throws {
        let nt212x = try ScannerSDK.shared.getNt212xParameterDefinitions()
        let nt280h = try ScannerSDK.shared.findNt280hParameter(byID: Nt280hParameters.qrCodeEnable)
        let se4750 = try ScannerSDK.shared.findSe4750Parameter(byID: Se4750Parameters.decodeSessionTimeout)
        let ntc06h = try ScannerSDK.shared.findNtc06hSetting(settingCode: "000705")

        XCTAssertGreaterThanOrEqual(nt212x.count, 174)
        XCTAssertEqual(try ScannerSDK.shared.findNt212xParameter(byID: Nt212xParameterAliases.qrCodeEnable)?.key, "F0_25")
        XCTAssertEqual(try ScannerSDK.shared.findNt212xParameter(byID: Nt212xParameterAliases.qrCodeEnable)?.aliasName, "QrCodeEnable")
        XCTAssertEqual(nt280h?.key, "DB_01")
        XCTAssertEqual(nt280h?.semanticName, "QrCodeEnable")
        XCTAssertEqual(se4750?.key, "88")
        XCTAssertEqual(se4750?.semanticName, "DecodeSessionTimeout")
        XCTAssertEqual(ntc06h?.key, "baud_rates_000705")
        XCTAssertEqual(ntc06h?.settingCode, "000705")
        XCTAssertEqual(ntc06h?.displayCode, "000705")
        XCTAssertEqual(ntc06h?.displayName, "9600bps")
        XCTAssertTrue(ntc06h?.requiresSave ?? false)

        let ntc06hTemplate = try ScannerSDK.shared.findNtc06hSetting(settingCode: "0087hh")
        XCTAssertEqual(ntc06hTemplate?.settingCode, "")
        XCTAssertEqual(ntc06hTemplate?.displayCode, "0087hh")
        XCTAssertTrue(ntc06hTemplate?.isTemplate ?? false)
        XCTAssertEqual(ntc06hTemplate?.templateHint, "hh 为两位十六进制长度值，例如 04 表示最小长度 4")
        XCTAssertEqual(ntc06hTemplate?.templateExampleCode, "008704")
        XCTAssertEqual(ntc06hTemplate?.templateInputType, .hexUInt8)
        XCTAssertEqual(ntc06hTemplate?.templateInputWidth, 2)
        XCTAssertEqual(ntc06hTemplate?.templateInputMin, 0)
        XCTAssertEqual(ntc06hTemplate?.templateInputMax, 255)
    }

    func testModuleParameterQuickValuesExposeRuntimeMetadata() throws {
        let values = try ScannerSDK.shared.getModuleParameterQuickValues(
            family: .se4750,
            parameterID: Se4750Parameters.decodeSessionTimeout
        )

        XCTAssertEqual(values.count, 5)
        XCTAssertEqual(values.first?.payloadHex, "05")
        XCTAssertEqual(values.first?.fallbackDisplayName, "0.5s")
        XCTAssertEqual(values.last?.payloadHex, "63")
    }

    func testModuleParameterNumericInputSpecExposeRuntimeMetadata() throws {
        let se4750Spec = try ScannerSDK.shared.getModuleParameterNumericInputSpec(
            family: .se4750,
            parameterID: Se4750Parameters.pDFPrioritizationTimeout
        )
        let nt212xSpec = try ScannerSDK.shared.getModuleParameterNumericInputSpec(
            family: .nt212x,
            parameterID: UInt32(Nt212xParameters.param12)
        )

        XCTAssertEqual(se4750Spec?.kind, .uint16Milliseconds)
        XCTAssertEqual(se4750Spec?.minValue, 0)
        XCTAssertEqual(se4750Spec?.maxValue, 5000)
        XCTAssertEqual(nt212xSpec?.kind, .uint8Decimal)
        XCTAssertEqual(nt212xSpec?.minValue, 0)
        XCTAssertEqual(nt212xSpec?.maxValue, 99)
    }

    func testModuleParameterBooleanPayloadPairExposeRuntimeMetadata() throws {
        let nt212xPair = try ScannerSDK.shared.getModuleParameterBooleanPayloadPair(
            family: .nt212x,
            parameterID: UInt32(Nt212xParameters.paramF025)
        )
        let nt280hPair = try ScannerSDK.shared.getModuleParameterBooleanPayloadPair(
            family: .nt280h,
            parameterID: UInt32(Nt280hParameters.qrCodeEnable)
        )
        let se4750Pair = try ScannerSDK.shared.getModuleParameterBooleanPayloadPair(
            family: .se4750,
            parameterID: Se4750Parameters.qRCode
        )
        let nonBoolPair = try ScannerSDK.shared.getModuleParameterBooleanPayloadPair(
            family: .se4750,
            parameterID: Se4750Parameters.decodeSessionTimeout
        )

        XCTAssertEqual(nt212xPair?.offPayloadHex, "00")
        XCTAssertEqual(nt212xPair?.onPayloadHex, "01")
        XCTAssertEqual(nt280hPair?.offPayloadHex, "0D")
        XCTAssertEqual(nt280hPair?.onPayloadHex, "0E")
        XCTAssertEqual(se4750Pair?.offPayloadHex, "00")
        XCTAssertEqual(se4750Pair?.onPayloadHex, "01")
        XCTAssertNil(nonBoolPair)
    }

    func testModuleParameterEnumLabelExposeRuntimeMetadata() throws {
        let leadingDigit = try ScannerSDK.shared.getModuleParameterEnumLabel(
            family: .nt280h,
            parameterID: UInt32(Nt280hParameters.upcATransmitLeadingDigit),
            rawLabel: "传输首位"
        )
        let enable = try ScannerSDK.shared.getModuleParameterEnumLabel(
            family: .nt212x,
            parameterID: UInt32(Nt212xParameters.paramF025),
            rawLabel: "Enable"
        )
        let unmapped = try ScannerSDK.shared.getModuleParameterEnumLabel(
            family: .se4750,
            parameterID: Se4750Parameters.decodeUPCEANJANSupplementals,
            rawLabel: "Unmapped Label"
        )

        XCTAssertEqual(leadingDigit?.fallbackDisplayName, "Transmit Leading Digit")
        XCTAssertEqual(enable?.localizationKey, "nsdk.module_parameter.enum_label.enable")
        XCTAssertNil(unmapped)
    }

    func testModuleParameterTitleLabelExposeRuntimeMetadata() throws {
        let overrideLabel = try ScannerSDK.shared.getModuleParameterTitleLabel(
            family: .se4750,
            parameterID: Se4750Parameters.beepAfterGoodDecode,
            aliasName: "",
            displayName: "Good Read Beep"
        )
        let tokenLabel = try ScannerSDK.shared.getModuleParameterTitleLabel(
            family: .nt212x,
            parameterID: UInt32(Nt212xParameters.paramF025),
            aliasName: "",
            displayName: "QR Code Enable"
        )
        let aliasLabel = try ScannerSDK.shared.getModuleParameterTitleLabel(
            family: .nt212x,
            parameterID: UInt32(Nt212xParameters.param11),
            aliasName: "All Symbology Switch",
            displayName: "Unknown Display"
        )

        XCTAssertEqual(overrideLabel?.localizationKey, "nsdk.module_parameter.title.good_read_beep")
        XCTAssertEqual(overrideLabel?.fallbackDisplayName, "Good Read Beep")
        XCTAssertEqual(tokenLabel?.localizationKey, "nsdk.module_parameter.title.qr_code_enable")
        XCTAssertEqual(aliasLabel?.localizationKey, "nsdk.module_parameter.title.all_symbology_switch")
    }

    func testNtc06hSettingTitleLabelUsesStableSettingKey() throws {
        let setting = try XCTUnwrap(
            try ScannerSDK.shared.getNtc06hSettingDefinitions().first { $0.key == "system_000b0" }
        )
        let label = setting.localizedTitleLabel

        XCTAssertEqual(label.localizationKey, "nsdk.ntc06h_setting.system_000b0")
        XCTAssertEqual(label.fallbackDisplayName, "恢复出厂值")
    }

    func testModuleParameterKindLabelExposeRuntimeMetadata() throws {
        let boolLabel = try ScannerSDK.shared.getModuleParameterKindLabel(.bool)
        let objectLabel = try ScannerSDK.shared.getModuleParameterKindLabel(.object)
        let uint8Label = try ScannerSDK.shared.getModuleParameterKindLabel(.uint8)

        XCTAssertEqual(boolLabel?.localizationKey, "nsdk.module_parameter.kind.bool")
        XCTAssertEqual(boolLabel?.fallbackDisplayName, "Boolean")
        XCTAssertEqual(objectLabel?.localizationKey, "nsdk.module_parameter.kind.object")
        XCTAssertEqual(uint8Label?.localizationKey, "nsdk.module_parameter.kind.uint8")
    }

    func testModuleCommandKindLabelExposeRuntimeMetadata() throws {
        let saveSettings = try ScannerSDK.shared.getModuleCommandKindLabel(.saveSettings)
        let capabilities = try ScannerSDK.shared.getModuleCommandKindLabel(.capabilitiesRequest)

        XCTAssertEqual(saveSettings.localizationKey, "nsdk.module_command_kind.save_settings")
        XCTAssertEqual(saveSettings.fallbackDisplayName, "Save Settings")
        XCTAssertEqual(capabilities.localizationKey, "nsdk.module_command_kind.capabilities_request")
        XCTAssertEqual(capabilities.fallbackDisplayName, "Read Capabilities")
    }

    func testMasterCommandGroupLabelsExposeRuntimeMetadata() throws {
        let wired = try ScannerSDK.shared.getMasterCommandCategoryLabel(.wired)
        XCTAssertEqual(wired.localizationKey, "nsdk.master_command_category.wired")
        XCTAssertEqual(wired.fallbackDisplayName, "USB")

        let powerSleep = try ScannerSDK.shared.getMasterCommandSectionLabel(.powerSleep)
        XCTAssertEqual(powerSleep.localizationKey, "nsdk.master_command_section.power_sleep")
        XCTAssertEqual(powerSleep.fallbackDisplayName, "Power & Sleep")

        let bluetoothTransport = try ScannerSDK.shared.getMasterCommandSectionLabel(.bluetoothTransport)
        XCTAssertEqual(bluetoothTransport.localizationKey, "nsdk.master_command_section.bluetooth_transport")
        XCTAssertEqual(bluetoothTransport.fallbackDisplayName, "BT")
    }

    func testCoreCommandLabelsExposeRuntimeMetadata() throws {
        let getInfo = try ScannerSDK.shared.getCommandCodeLabel(.getInfo)
        XCTAssertEqual(getInfo.localizationKey, "nsdk.command_code.get_info")
        XCTAssertEqual(getInfo.fallbackDisplayName, "Refresh Info")

        let ackBeep = try ScannerSDK.shared.getCommandCodeLabel(.beep)
        XCTAssertEqual(ackBeep.localizationKey, "nsdk.command_code.beep")
        XCTAssertEqual(ackBeep.fallbackDisplayName, "Ack Beep On")

        let readSleep = try ScannerSDK.shared.getMasterCommandLabel(.readSleepTime)
        XCTAssertEqual(readSleep.localizationKey, "nsdk.master_command.read_sleep_time")
        XCTAssertEqual(readSleep.fallbackDisplayName, "Read Sleep")

        let module = try ScannerSDK.shared.getMasterCommandLabel(.setDecoderModule3)
        XCTAssertEqual(module.localizationKey, "nsdk.master_command.set_decoder_module3")
        XCTAssertEqual(module.fallbackDisplayName, "NT280H")

        let getVersion = try ScannerSDK.shared.getBasicDeviceCommandLabel(.getVersion)
        XCTAssertEqual(getVersion.localizationKey, "nsdk.basic_device_command.get_version")
        XCTAssertEqual(getVersion.fallbackDisplayName, "Get Version")

        let uploadClear = try ScannerSDK.shared.getBasicDeviceCommandLabel(.uploadMemoryDataAndClear)
        XCTAssertEqual(uploadClear.localizationKey, "nsdk.basic_device_command.upload_memory_data_and_clear")
        XCTAssertEqual(uploadClear.fallbackDisplayName, "Upload + Clear")

        let prefix = try ScannerSDK.shared.getDataRuleKindLabel(.prefix)
        XCTAssertEqual(prefix.localizationKey, "nsdk.data_rule_command_kind.prefix")
        XCTAssertEqual(prefix.fallbackDisplayName, "Prefix")

        let replace = try ScannerSDK.shared.getDataRuleKindLabel(.replace)
        XCTAssertEqual(replace.localizationKey, "nsdk.data_rule_command_kind.replace")
        XCTAssertEqual(replace.fallbackDisplayName, "Replace")
    }

    func testCommandRiskLabelsExposeRuntimeMetadata() {
        let commandRisk = CommandCodeRiskLabel(
            localizationKey: "nsdk.command_code_risk.this_enables_the_device_acknowledgment_beep_and_changes_feedback_behavior_immediately",
            fallbackDisplayName: "This enables the device acknowledgment beep and changes feedback behavior immediately."
        )
        XCTAssertEqual(commandRisk.localizationKey, "nsdk.command_code_risk.this_enables_the_device_acknowledgment_beep_and_changes_feedback_behavior_immediately")
        XCTAssertEqual(commandRisk.fallbackDisplayName, "This enables the device acknowledgment beep and changes feedback behavior immediately.")

        let runtimeCommandRisk = CommandCode.vibrateOn.localizedRiskLabel
        XCTAssertEqual(runtimeCommandRisk.localizationKey, "nsdk.command_code_risk.this_enables_vibration_feedback_and_changes_feedback_behavior_immediately")
        XCTAssertEqual(runtimeCommandRisk.fallbackDisplayName, "This enables vibration feedback and changes feedback behavior immediately.")

        let basicRisk = BasicDeviceCommandRiskLabel(
            localizationKey: "nsdk.basic_device_command_risk.this_restores_factory_defaults_and_may_erase_the_current_configuration",
            fallbackDisplayName: "This restores defaults. If custom defaults exist, those values are restored; otherwise factory defaults are restored."
        )
        XCTAssertEqual(basicRisk.localizationKey, "nsdk.basic_device_command_risk.this_restores_factory_defaults_and_may_erase_the_current_configuration")
        XCTAssertEqual(basicRisk.fallbackDisplayName, "This restores defaults. If custom defaults exist, those values are restored; otherwise factory defaults are restored.")

        let runtimeBasicRisk = BasicDeviceCommand.clearMemory.localizedRiskLabel
        XCTAssertEqual(runtimeBasicRisk.localizationKey, "nsdk.basic_device_command_risk.this_affects_stored_barcode_data_on_the_device_and_may_be_irreversible")
        XCTAssertEqual(runtimeBasicRisk.fallbackDisplayName, "This affects stored barcode data on the device and may be irreversible.")

        let masterRisk = MasterCommandRiskLabel(
            localizationKey: "nsdk.master_command_risk.the_device_may_sleep_immediately_or_disconnect",
            fallbackDisplayName: "The device may sleep immediately or disconnect."
        )
        XCTAssertEqual(masterRisk.localizationKey, "nsdk.master_command_risk.the_device_may_sleep_immediately_or_disconnect")
        XCTAssertEqual(masterRisk.fallbackDisplayName, "The device may sleep immediately or disconnect.")

        let runtimeMasterRisk = MasterCommand.bluetoothBle.localizedRiskLabel
        XCTAssertEqual(runtimeMasterRisk.localizationKey, "nsdk.master_command_risk.this_changes_the_interface_or_transport_mode_and_may_interrupt_the_current_ble_link")
        XCTAssertEqual(runtimeMasterRisk.fallbackDisplayName, "This changes the interface or transport mode and may interrupt the current BLE link.")

        let fallbackMasterRisk = MasterCommand.mute.localizedRiskLabel
        XCTAssertEqual(fallbackMasterRisk.localizationKey, "nsdk.master_command_risk.this_is_a_high_risk_operation_make_sure_the_test_device_can_safely_execute_it")
        XCTAssertEqual(fallbackMasterRisk.fallbackDisplayName, "This is a high-risk operation. Make sure the test device can safely execute it.")
    }

    func testModuleActionPresetLabelExposeRuntimeMetadata() throws {
        let scan = try ScannerSDK.shared.getModuleActionPresetLabel(actionID: "nt280h_scan_auto")
        XCTAssertEqual(scan?.actionID, "nt280h_scan_auto")
        XCTAssertEqual(scan?.localizationKey, "nsdk.module_action_preset.nt280h_scan_auto")
        XCTAssertEqual(scan?.fallbackDisplayName, "Auto Scan")

        let unknown = try ScannerSDK.shared.getModuleActionPresetLabel(actionID: "unknown_action")
        XCTAssertNil(unknown)
    }

    func testModuleTestRecommendationsExposeRuntimeMetadata() throws {
        let nt212x = try ScannerSDK.shared.getModuleTestRecommendations(family: .nt212x)
        XCTAssertEqual(nt212x.count, 3)
        XCTAssertEqual(nt212x.first?.recommendationID, "nt212x_qr")
        XCTAssertEqual(nt212x.first?.titleKey, "nsdk.module_test_recommendation.nt212x_qr.title")
        XCTAssertEqual(nt212x.first?.titleFallback, "Start with QR switch")

        let ntc06h = try ScannerSDK.shared.getModuleTestRecommendations(family: .ntc06h)
        XCTAssertEqual(ntc06h.last?.recommendationID, "ntc06h_comm")
        XCTAssertEqual(ntc06h.last?.titleKey, "nsdk.module_test_recommendation.ntc06h_comm.title")
        XCTAssertEqual(ntc06h.last?.titleFallback, "Leave communication mode for last")

        let unknown = try ScannerSDK.shared.getModuleTestRecommendations(family: .unknown)
        XCTAssertTrue(unknown.isEmpty)
    }

    func testModuleTaxonomyExposeRuntimeMetadata() throws {
        let groups = try ScannerSDK.shared.getModuleTaxonomyEntries(kind: .group)
        let domains = try ScannerSDK.shared.getModuleTaxonomyEntries(kind: .domain)

        XCTAssertEqual(groups.first?.key, "symbology_global")
        XCTAssertEqual(groups.first?.rank, 0)
        XCTAssertEqual(groups.first?.localizationKey, "nsdk.module_taxonomy.group.symbology_global")
        XCTAssertEqual(groups.first?.fallbackDisplayName, "Global Symbology")
        XCTAssertEqual(domains[1].key, "scan")
        XCTAssertEqual(domains[1].rank, 1)
        XCTAssertEqual(domains[1].localizationKey, "nsdk.module_taxonomy.domain.scan")
        XCTAssertEqual(domains[1].fallbackDisplayName, "Scanning")
        XCTAssertEqual(ModuleTaxonomyCatalog.rank(of: .section, key: "ack"), 37)
        XCTAssertEqual(ModuleTaxonomyCatalog.entry(of: .section, key: "variant")?.localizationKey, "nsdk.module_taxonomy.section.variant")
        XCTAssertEqual(
            ModuleTaxonomyCatalog.sortKeys(["zzz", "scan", "advanced"], for: .domain),
            ["scan", "advanced", "zzz"]
        )
    }

    func testModuleTaxonomyGroupingBuildsCanonicalHierarchy() {
        let items = [
            Nt212xParameterDefinition(
                parameterID: 0x10,
                key: "10",
                aliasName: "UnknownDomain",
                displayName: "Unknown Domain",
                symbol: "param_10",
                group: "zzz",
                domainKey: "zzz",
                familyKey: "zzz",
                sectionKey: "zzz",
                defaultValue: "",
                optionsJSON: "{}",
                kind: .bool
            ),
            Nt212xParameterDefinition(
                parameterID: 0x11,
                key: "11",
                aliasName: "ScanMode",
                displayName: "Scan Mode",
                symbol: "param_11",
                group: "scan",
                domainKey: "scan",
                familyKey: "trigger_timing",
                sectionKey: "mode",
                defaultValue: "",
                optionsJSON: "{}",
                kind: .bool
            ),
            Nt212xParameterDefinition(
                parameterID: 0x12,
                key: "12",
                aliasName: "AckBeep",
                displayName: "Ack Beep",
                symbol: "param_12",
                group: "indicators",
                domainKey: "feedback",
                familyKey: "beeper",
                sectionKey: "ack",
                defaultValue: "",
                optionsJSON: "{}",
                kind: .bool
            ),
            Nt212xParameterDefinition(
                parameterID: 0x13,
                key: "13",
                aliasName: "GeneralBeep",
                displayName: "General Beep",
                symbol: "param_13",
                group: "indicators",
                domainKey: "feedback",
                familyKey: "beeper",
                sectionKey: "general",
                defaultValue: "",
                optionsJSON: "{}",
                kind: .bool
            ),
        ]

        XCTAssertEqual(ModuleTaxonomyGrouping.groupKeys(items), ["scan", "indicators", "zzz"])

        let grouped = ModuleTaxonomyGrouping.domainGroups(items) { lhs, rhs in
            lhs.parameterID < rhs.parameterID
        }

        XCTAssertEqual(grouped.map(\.key), ["scan", "feedback", "zzz"])
        XCTAssertEqual(grouped[0].families.map(\.key), ["trigger_timing"])
        XCTAssertEqual(grouped[1].families.map(\.key), ["beeper"])
        XCTAssertEqual(grouped[1].families[0].sections.map(\.key), ["general", "ack"])
        XCTAssertEqual(grouped[1].families[0].sections[0].items.map(\.parameterID), [0x13])
        XCTAssertEqual(grouped[1].families[0].sections[1].items.map(\.parameterID), [0x12])
    }

    func testPendingStateIsDeliveredAfterSessionRegistration() {
        let sdk = ScannerSDK.makeTestingInstance()

        sdk.simulatePendingState(.connected, handle: 100)
        sdk.simulatePendingState(.ready, handle: 100)

        let session = sdk.registerSessionForTesting(handle: 100)

        XCTAssertEqual(session.latestState, .ready)
    }

    func testDisconnectedStateRemovesSessionFromSdk() {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 101)

        XCTAssertNotNil(sdk.findSession(handle: 101))

        session.onStateChanged(.disconnected)

        XCTAssertNil(sdk.findSession(handle: 101))
    }

    func testScanCharsetDecodingUsesConfiguredCharset() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 102)
        session.setScanTextCharset(.utf8)
        let stream = session.scanEvents

        let received = expectation(description: "scan event decoded")
        var scannedText: String?
        let payload = Data([0xE4, 0xB8, 0xAD, 0xE6, 0x96, 0x87])
        Task {
            var iterator = stream.makeAsyncIterator()
            let event = await iterator.next()
            scannedText = event?.text
            received.fulfill()
        }
        await Task.yield()

        session.onScanEvent(timestampMs: 1, barcodeType: 0, textBytes: payload, rawBytes: payload + Data([0x0D]))

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertEqual(scannedText, "中文")
    }

    func testCommandResponseTextTruncationUsesAvailableBytesOnly() throws {
        var response = nsdk_command_response_t()
        let available = Data([0x41, 0x42, 0x43])
        available.withUnsafeBytes { rawBuffer in
            withUnsafeMutableBytes(of: &response.text_bytes) { textBuffer in
                textBuffer.copyBytes(from: rawBuffer)
            }
        }
        response.text_size = UInt32(available.count)
        response.text_full_size = 5

        var mutableResponse = response
        let copied = try copyBytes(
            expectedLength: mutableResponse.text_size,
            copy: { buffer, capacity, outLength in
                nsdk_command_response_copy_text_bytes(&mutableResponse, buffer, capacity, outLength)
            },
            operation: "test.copyCommandResponseTextBytes"
        )
        let commandResponse = CommandResponse(
            textBytes: copied,
            textFullSize: Int(mutableResponse.text_full_size),
            textBytesComplete: mutableResponse.text_size >= mutableResponse.text_full_size,
            rawBytes: Data(),
            acknowledged: false,
            recordCount: 0,
            recordBytes: [],
            recordsComplete: true
        )

        XCTAssertEqual(commandResponse.textBytes, available)
        XCTAssertEqual(commandResponse.textFullSize, 5)
        XCTAssertFalse(commandResponse.textBytesComplete)
        XCTAssertTrue(commandResponse.textTruncated)
    }

    func testScanTextCharsetAndTerminatorPresetsExposeStableDisplayMetadata() {
        XCTAssertEqual(ScanTextCharset.utf8.displayName, "UTF_8")
        XCTAssertEqual(ScanTextCharset.usASCII.displayName, "US_ASCII")
        XCTAssertEqual(ScanTextCharset.iso88591.displayName, "ISO_8859_1")
        XCTAssertEqual(ScanTextCharset.gbk.displayName, "GBK")

        XCTAssertEqual(ScanTerminatorPreset.defaults.map(\.label), ["CR", "LF", "CRLF", "TAB"])
        XCTAssertEqual(ScanTerminatorPreset.defaults.map(\.summary), ["0D", "0A", "0D 0A", "09"])
        XCTAssertEqual(ScanTerminatorPreset.cr.bytes, Data([0x0D]))
    }

    func testDeviceConfigEnumsExposeStableLocalizedDisplayMetadata() {
        XCTAssertEqual(DeviceCharset.auto.displayName, "Auto")
        XCTAssertEqual(DeviceCharset.auto.localizedLabel.localizationKey, "nsdk.device_charset.auto")
        XCTAssertEqual(DeviceCharset.auto.localizedLabel.fallbackDisplayName, "Auto")
        XCTAssertEqual(DeviceCharset.utf8Txt.localizedLabel.localizationKey, "nsdk.device_charset.utf8_txt")
        XCTAssertEqual(DeviceCharset.utf8Txt.localizedLabel.fallbackDisplayName, "UTF8 (Txt)")

        XCTAssertEqual(DeviceTerminalCode.none.displayName, "None")
        XCTAssertEqual(DeviceTerminalCode.none.localizedLabel.localizationKey, "nsdk.device_terminal_code.none")
        XCTAssertEqual(DeviceTerminalCode.none.localizedLabel.fallbackDisplayName, "None")
        XCTAssertEqual(DeviceTerminalCode.crlf.localizedLabel.localizationKey, "nsdk.device_terminal_code.crlf")
        XCTAssertEqual(DeviceTerminalCode.crlf.localizedLabel.fallbackDisplayName, "CRLF")

        XCTAssertEqual(KeyboardLayout.en.displayName, "EN")
        XCTAssertEqual(KeyboardLayout.en.localizedLabel.localizationKey, "nsdk.keyboard_layout.en")
        XCTAssertEqual(KeyboardLayout.en.localizedLabel.fallbackDisplayName, "EN")
        XCTAssertEqual(ReceiveDeviceType.macOsIos.displayName, "Mac/iOS")
        XCTAssertEqual(ReceiveDeviceType.macOsIos.localizedLabel.localizationKey, "nsdk.receive_device_type.mac_ios")
        XCTAssertEqual(ReceiveDeviceType.macOsIos.localizedLabel.fallbackDisplayName, "Mac/iOS")
    }

    func testPendingScanIsDeliveredWhenSubscriberAlreadyAttached() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 103)
        session.setScanTextCharset(.utf8)
        let stream = session.scanEvents

        let received = expectation(description: "pending scan delivered")
        var eventText: String?
        var eventTextBytes = Data()
        var eventRawBytes = Data()
        Task {
            var iterator = stream.makeAsyncIterator()
            let event = await iterator.next()
            eventText = event?.text
            eventTextBytes = event?.textBytes ?? Data()
            eventRawBytes = event?.rawBytes ?? Data()
            received.fulfill()
        }
        await Task.yield()

        sdk.simulatePendingScan(
            handle: 103,
            timestampMs: 123,
            barcodeType: 7,
            textBytes: Data("ABC123".utf8),
            rawBytes: Data("ABC123\r".utf8)
        )
        sdk.simulatePendingState(.ready, handle: 103)

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertEqual(eventText, "ABC123")
        XCTAssertEqual(eventTextBytes, Data("ABC123".utf8))
        XCTAssertEqual(eventRawBytes, Data("ABC123\r".utf8))
    }

    func testScannerInfoKeepsStructuredQueryFieldsStable() {
        let info = ScannerInfo(
            deviceId: "device-1",
            name: "scanner-name",
            serialNumber: "SN123",
            firmwareVersion: "FW1.0",
            hardwareVersion: "HW2.0",
            manufacturer: "NLS",
            versionFormatFamily: "family",
            versionBootCode: "boot",
            versionSeriesCode: "customer",
            versionTransportCode: "transport",
            versionTransportSuffix: "suffix",
            versionWirelessCode: "wireless",
            versionBluetoothCode: "btcode",
            versionChipsetCode: "chip",
            versionChipsetSuffix: "chipsfx",
            versionReleaseCode: "release",
            versionExtensionCode: "ext"
        )

        XCTAssertEqual(info.deviceId, "device-1")
        XCTAssertEqual(info.name, "scanner-name")
        XCTAssertEqual(info.serialNumber, "SN123")
        XCTAssertEqual(info.firmwareVersion, "FW1.0")
        XCTAssertEqual(info.hardwareVersion, "HW2.0")
        XCTAssertEqual(info.manufacturer, "NLS")
        XCTAssertEqual(info.versionFormatFamily, "family")
        XCTAssertEqual(info.versionBootCode, "boot")
        XCTAssertEqual(info.versionSeriesCode, "customer")
        XCTAssertEqual(info.versionTransportCode, "transport")
        XCTAssertEqual(info.versionTransportSuffix, "suffix")
        XCTAssertEqual(info.versionWirelessCode, "wireless")
        XCTAssertEqual(info.versionBluetoothCode, "btcode")
        XCTAssertEqual(info.versionChipsetCode, "chip")
        XCTAssertEqual(info.versionChipsetSuffix, "chipsfx")
        XCTAssertEqual(info.versionReleaseCode, "release")
        XCTAssertEqual(info.versionExtensionCode, "ext")
    }

    func testScannerInfoBridgeMapsAllStructuredFieldsFromCStruct() {
        let session = ScannerSDK.makeTestingInstance().registerSessionForTesting(handle: 200)
        var raw = nsdk_scanner_info_t()
        copyCString("device-1", into: &raw.device_id)
        copyCString("scanner-name", into: &raw.name)
        copyCString("SN123", into: &raw.serial_number)
        copyCString("FW1.0", into: &raw.firmware_version)
        copyCString("HW2.0", into: &raw.hardware_version)
        copyCString("NLS", into: &raw.manufacturer)
        copyCString("family", into: &raw.version_format_family)
        copyCString("boot", into: &raw.version_boot_code)
        copyCString("customer", into: &raw.version_series_code)
        copyCString("transport", into: &raw.version_transport_code)
        copyCString("suffix", into: &raw.version_transport_suffix)
        copyCString("wireless", into: &raw.version_wireless_code)
        copyCString("btcode", into: &raw.version_bluetooth_code)
        copyCString("chip", into: &raw.version_chipset_code)
        copyCString("chipsfx", into: &raw.version_chipset_suffix)
        copyCString("release", into: &raw.version_release_code)
        copyCString("ext", into: &raw.version_extension_code)

        let info = session.makeScannerInfo(raw)

        XCTAssertEqual(info.deviceId, "device-1")
        XCTAssertEqual(info.name, "scanner-name")
        XCTAssertEqual(info.serialNumber, "SN123")
        XCTAssertEqual(info.firmwareVersion, "FW1.0")
        XCTAssertEqual(info.hardwareVersion, "HW2.0")
        XCTAssertEqual(info.manufacturer, "NLS")
        XCTAssertEqual(info.versionFormatFamily, "family")
        XCTAssertEqual(info.versionBootCode, "boot")
        XCTAssertEqual(info.versionSeriesCode, "customer")
        XCTAssertEqual(info.versionTransportCode, "transport")
        XCTAssertEqual(info.versionTransportSuffix, "suffix")
        XCTAssertEqual(info.versionWirelessCode, "wireless")
        XCTAssertEqual(info.versionBluetoothCode, "btcode")
        XCTAssertEqual(info.versionChipsetCode, "chip")
        XCTAssertEqual(info.versionChipsetSuffix, "chipsfx")
        XCTAssertEqual(info.versionReleaseCode, "release")
        XCTAssertEqual(info.versionExtensionCode, "ext")
    }

    func testPendingFailureIsDeliveredAfterSessionRegistration() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 201, deviceId: "AA:BB", transportType: .bleGatt)
        let stream = session.failureEvents
        let received = expectation(description: "pending failure delivered")
        var failure: SessionFailure?

        sdk.simulatePendingFailure(
            handle: 201,
            transport: .bleGatt,
            code: .connectionTimeout,
            platformErrorCode: 8
        )

        Task {
            var iterator = stream.makeAsyncIterator()
            failure = await iterator.next()
            received.fulfill()
        }
        await Task.yield()

        _ = sdk.registerSessionForTesting(session)

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertEqual(failure?.code, .connectionTimeout)
        XCTAssertEqual(failure?.deviceId, "AA:BB")
        XCTAssertEqual(failure?.platformErrorCode, 8)
    }

    func testPendingInitializationStageIsDeliveredAfterSessionRegistration() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.makeTestingSession(handle: 202, deviceId: "AA:BB", transportType: .bleGatt)
        let stream = session.initializationStages
        let received = expectation(description: "pending initialization stage delivered")
        var stageEvent: SessionInitializationStageEvent?

        sdk.simulatePendingInitializationStage(
            handle: 202,
            selectedModelId: .cs7501,
            stage: .readingBattery,
            timestampMs: 456,
            traceId: 789,
            success: true,
            errorCode: 0,
            message: "battery stage"
        )

        Task {
            var iterator = stream.makeAsyncIterator()
            stageEvent = await iterator.next()
            received.fulfill()
        }
        await Task.yield()

        _ = sdk.registerSessionForTesting(session)

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertEqual(stageEvent?.selectedModelId, .cs7501)
        XCTAssertEqual(stageEvent?.stage, .readingBattery)
        XCTAssertEqual(stageEvent?.timestampMs, 456)
        XCTAssertEqual(stageEvent?.traceId, 789)
        XCTAssertEqual(stageEvent?.deviceId, "AA:BB")
        XCTAssertEqual(stageEvent?.message, "battery stage")
        XCTAssertEqual(stageEvent?.success, true)
    }

    func testTransportFailureLabelsExposeRuntimeMetadata() {
        let setupStatus = TransportFailureCode.notifyDescriptorMissing.localizedStatusLabel
        XCTAssertEqual(setupStatus.localizationKey, "nsdk.transport_failure_status.connection_setup_failed")
        XCTAssertEqual(setupStatus.fallbackDisplayName, "Connection setup failed")

        let timeoutStatus = TransportFailureCode.connectionTimeout.localizedStatusLabel
        XCTAssertEqual(timeoutStatus.localizationKey, "nsdk.transport_failure_status.connection_timed_out")
        XCTAssertEqual(timeoutStatus.fallbackDisplayName, "Connection timed out")

        let codeLabel = TransportFailureCode.platformStatusError.localizedLabel
        XCTAssertEqual(codeLabel.localizationKey, "nsdk.transport_failure_code.platform_connection_status_error")
        XCTAssertEqual(codeLabel.fallbackDisplayName, "Platform connection status error")

        let issueLabel = BleTransportIssue.unknown.localizedLabel
        XCTAssertEqual(issueLabel.localizationKey, "nsdk.ble_transport_issue.unknown_ble_transport_issue")
        XCTAssertEqual(issueLabel.fallbackDisplayName, "Unknown BLE transport issue")
    }

    func testDiscoveryFailureLabelsExposeRuntimeMetadata() {
        let codeLabel = DiscoveryFailureCode.bleAdapterDisabled.localizedLabel
        XCTAssertEqual(codeLabel.localizationKey, "nsdk.discovery_failure_code.bluetooth_disabled")
        XCTAssertEqual(codeLabel.fallbackDisplayName, "Bluetooth disabled")

        let issueLabel = BleScanIssue.outOfHardwareResources.localizedLabel
        XCTAssertEqual(issueLabel.localizationKey, "nsdk.ble_scan_issue.out_of_hardware_resources")
        XCTAssertEqual(issueLabel.fallbackDisplayName, "Out of hardware resources")

        let recoverableFailure = DiscoveryFailure(
            transportType: .bleGatt,
            code: .bleFilteredScanFailed,
            message: "fallback",
            bleScanIssue: nil,
            platformErrorCode: nil,
            recoverable: true
        )
        XCTAssertEqual(recoverableFailure.localizedStatusLabel.localizationKey, "nsdk.discovery_failure_status.discovery_downgraded_to_fallback_mode")
        XCTAssertEqual(recoverableFailure.localizedStatusLabel.fallbackDisplayName, "Discovery downgraded to fallback mode")
    }

    func testDiscoveryFailureBridgeUsesSharedNativeNormalization() {
        var rawFailure = nsdk_discovery_failure_t()
        var hasFailure: Int32 = 0
        XCTAssertEqual(
            nsdk_make_apple_ble_discovery_failure_for_central_state(2, &rawFailure, &hasFailure),
            0
        )
        XCTAssertEqual(hasFailure, 1)
        let failure = DiscoveryFailure(cValue: rawFailure)
        XCTAssertEqual(failure.transportType, .bleGatt)
        XCTAssertEqual(failure.code, .bleScannerUnavailable)
        XCTAssertEqual(failure.bleScanIssue, .featureUnsupported)
        XCTAssertEqual(
            failure.message,
            "BLE discovery unavailable: BLE is not supported on this device"
        )
        XCTAssertFalse(failure.recoverable)
    }

    func testDebugEventsDeliverSdkDebugMessages() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let stream = sdk.debugEvents
        let received = expectation(description: "debug event delivered")
        var message: String?

        Task {
            var iterator = stream.makeAsyncIterator()
            message = await iterator.next()
            received.fulfill()
        }
        await Task.yield()

        sdk.emitDebug("hello debug")

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertEqual(message, "hello debug")
    }

    func testSessionStateChangesMirrorIntoDebugEvents() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 301)
        let stream = sdk.debugEvents
        let received = expectation(description: "state debug event delivered")
        var message: String?

        Task {
            var iterator = stream.makeAsyncIterator()
            while let event = await iterator.next() {
                if event.contains("session[301] state=ready") {
                    message = event
                    received.fulfill()
                    return
                }
            }
        }
        await Task.yield()

        session.onStateChanged(.ready)

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertEqual(message, "session[301] state=ready")
    }

    func testSessionFailureMirrorsIntoDebugEvents() async {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 302)
        let stream = sdk.debugEvents
        let received = expectation(description: "failure debug event delivered")
        var message: String?

        Task {
            var iterator = stream.makeAsyncIterator()
            while let event = await iterator.next() {
                if event.contains("session[302] failure transport=bleGatt code=connectionTimeout") {
                    message = event
                    received.fulfill()
                    return
                }
            }
        }
        await Task.yield()

        session.onFailure(
            SessionFailure(
                sessionHandle: 302,
                deviceId: "AA:BB",
                transportType: .bleGatt,
                code: .connectionTimeout,
                message: "timeout",
                bleTransportIssue: .connectionTimeout,
                platformErrorCode: 8
            )
        )

        await fulfillment(of: [received], timeout: 1.0)
        XCTAssertNotNil(message)
        XCTAssertTrue(message?.contains("session[302] failure transport=bleGatt code=connectionTimeout") ?? false)
        XCTAssertTrue(message?.contains("platformError=Optional(8)") ?? false)
    }

    func testCapabilityDiagnosticsFlagDowngradedModuleSupport() {
        let sdk = ScannerSDK.makeTestingInstance()
        let session = sdk.registerSessionForTesting(handle: 303)
        let diagnostics = session.capabilityDiagnostics(
            DeviceCapabilitySummary(
                modelId: .cs7501,
                modelName: "CS7501",
                defaultCommandSet: .masterWithModuleInfo,
                formFactor: .masterWithModule,
                moduleFamily: .se4750,
                supportsBasicDeviceCommands: true,
                supportsMasterCommands: true,
                supportsNativeModuleCommands: false,
                supportsModuleCommandBridge: false,
                supportsModuleCommands: false,
                supportsScannerMaster: true,
                supportsModulePassthrough: true,
                supportStatus: .codeOnly
            )
        )

        XCTAssertTrue(diagnostics.contains("capability-warning supportStatus=codeOnly"))
        XCTAssertTrue(diagnostics.contains("capability-warning moduleFamily=se4750 but moduleCommands=false"))
        XCTAssertTrue(diagnostics.contains("capability-warning passthroughOnly family=se4750"))
    }

}
