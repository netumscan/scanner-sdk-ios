import Foundation

public extension CommandResponse {
    func nt212xParameterValueBytes(parameterID: UInt16) -> Data {
        precondition(parameterID != 0, "parameterID must not be zero")
        precondition(moduleParameterValueAvailable, "Response does not contain a structured NT212X parameter value.")
        precondition(moduleParameterID == Int(parameterID), "Response parameter id does not match requested NT212X parameter.")
        return moduleParameterValueBytes
    }

    func nt212xBooleanParameterValue(parameterID: UInt16) -> Bool {
        let valueBytes = nt212xParameterValueBytes(parameterID: parameterID)
        precondition(valueBytes.count == 1, "Expected a single-byte boolean parameter value.")
        return valueBytes.first != 0x00
    }
}

public extension ScannerSession {
    func readNt212xParameter(_ parameterID: UInt16) throws -> CommandResponse {
        precondition(parameterID != 0, "parameterID must not be zero")
        return try executeModuleCommand(
            family: .nt212x,
            kind: .readParameter,
            parameterID: UInt32(parameterID)
        )
    }

    func writeNt212xParameter(
        _ parameterID: UInt16,
        valueBytes: Data,
        persist: Bool = true
    ) throws -> CommandResponse {
        precondition(parameterID != 0, "parameterID must not be zero")
        return try executeModuleCommand(
            family: .nt212x,
            kind: .writeParameter,
            parameterID: UInt32(parameterID),
            payload: valueBytes,
            persist: persist
        )
    }

    func getQrCodeEnabled() throws -> Bool {
        let response = try readNt212xParameter(Nt212xParameterAliases.qrCodeEnable)
        return response.nt212xBooleanParameterValue(parameterID: Nt212xParameterAliases.qrCodeEnable)
    }

    func setQrCodeEnabled(
        _ enabled: Bool,
        persist: Bool = true
    ) throws -> CommandResponse {
        try writeNt212xParameter(
            Nt212xParameterAliases.qrCodeEnable,
            valueBytes: Data([enabled ? 0x01 : 0x00]),
            persist: persist
        )
    }
}
