import Foundation

public extension CommandResponse {
    func nt280hParameterValueBytes(parameterID: UInt16) -> Data {
        precondition(parameterID != 0, "parameterID must not be zero")
        let parameter = Nt280hParameterCatalog.findByID(parameterID)
        precondition(parameter != nil, "Unknown NT280H parameter.")
        precondition(parameter?.isPlaceholder == false, "Placeholder metadata does not have a device response payload.")

        precondition(moduleParameterValueAvailable, "Response does not contain a structured NT280H parameter value.")
        precondition(moduleParameterID == Int(parameterID), "Response parameter id does not match requested NT280H parameter.")
        return moduleParameterValueBytes
    }

    func nt280hBooleanParameterValue(parameterID: UInt16) -> Bool {
        let valueBytes = nt280hParameterValueBytes(parameterID: parameterID)
        precondition(valueBytes.count == 1, "Expected a single-byte boolean parameter value.")
        return valueBytes.first != 0x00
    }
}

public extension ScannerSession {
    func readNt280hParameter(_ parameterID: UInt16) throws -> CommandResponse {
        precondition(parameterID != 0, "parameterID must not be zero")
        return try executeModuleCommand(
            family: .nt280h,
            kind: .readParameter,
            parameterID: UInt32(parameterID)
        )
    }

    func writeNt280hParameter(
        _ parameterID: UInt16,
        valueBytes: Data,
        persist: Bool = true
    ) throws -> CommandResponse {
        precondition(parameterID != 0, "parameterID must not be zero")
        return try executeModuleCommand(
            family: .nt280h,
            kind: .writeParameter,
            parameterID: UInt32(parameterID),
            payload: valueBytes,
            persist: persist
        )
    }
}
