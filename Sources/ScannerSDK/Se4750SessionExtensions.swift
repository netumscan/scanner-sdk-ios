import Foundation

public extension CommandResponse {
    func se4750ParameterValueBytes(parameterID: UInt32) -> Data {
        precondition(parameterID != 0, "parameterID must not be zero")
        precondition(moduleParameterValueAvailable, "Response does not contain a structured SE4750 parameter value.")
        precondition(moduleParameterID == Int(parameterID), "Response parameter id does not match requested SE4750 parameter.")
        return moduleParameterValueBytes
    }

    func se4750BooleanParameterValue(parameterID: UInt32) -> Bool {
        let valueBytes = se4750ParameterValueBytes(parameterID: parameterID)
        precondition(valueBytes.count == 1, "Expected a single-byte boolean parameter value.")
        return valueBytes.first != 0x00
    }
}

public extension ScannerSession {
    func readSe4750Parameter(_ parameterID: UInt32) throws -> CommandResponse {
        precondition(parameterID != 0, "parameterID must not be zero")
        return try executeModuleCommand(
            family: .se4750,
            kind: .readParameter,
            parameterID: parameterID
        )
    }

    func writeSe4750Parameter(
        _ parameterID: UInt32,
        valueBytes: Data,
        persist: Bool = true
    ) throws -> CommandResponse {
        precondition(parameterID != 0, "parameterID must not be zero")
        return try executeModuleCommand(
            family: .se4750,
            kind: .writeParameter,
            parameterID: parameterID,
            payload: valueBytes,
            persist: persist
        )
    }

    func requestSe4750Capabilities() throws -> CommandResponse {
        try executeModuleCommand(
            family: .se4750,
            kind: .capabilitiesRequest
        )
    }

    func setSe4750AimEnabled(_ enabled: Bool) throws -> CommandResponse {
        try executeModuleCommand(
            family: .se4750,
            kind: enabled ? .aimOn : .aimOff
        )
    }

    func setSe4750IlluminationEnabled(_ enabled: Bool) throws -> CommandResponse {
        try executeModuleCommand(
            family: .se4750,
            kind: enabled ? .illuminationOn : .illuminationOff
        )
    }

    func setSe4750AllCodeTypes(payload: Data) throws -> CommandResponse {
        precondition(!payload.isEmpty, "payload must not be empty")
        return try executeModuleCommand(
            family: .se4750,
            kind: .changeAllCodeTypes,
            payload: payload
        )
    }

    func beepSe4750(payload: Data = Data()) throws -> CommandResponse {
        try executeModuleCommand(
            family: .se4750,
            kind: .beep,
            payload: payload
        )
    }

    func activateSe4750Pager(payload: Data = Data()) throws -> CommandResponse {
        try executeModuleCommand(
            family: .se4750,
            kind: .pagerMotorActivation,
            payload: payload
        )
    }
}
