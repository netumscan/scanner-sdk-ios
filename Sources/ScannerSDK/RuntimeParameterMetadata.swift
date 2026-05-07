import Foundation
import CNSDK

extension Nt212xParameterKind {
    init(cValue: nsdk_nt212x_parameter_kind_t) {
        switch cValue.rawValue {
        case 1:
            self = .bool
        case 2:
            self = .enum
        case 3:
            self = .uint8
        case 4:
            self = .uint16
        case 5:
            self = .bytesAscii
        case 6:
            self = .action
        case 7:
            self = .complex
        case 8:
            self = .custom
        default:
            self = .unknown
        }
    }
}

extension Nt280hParameterKind {
    init(cValue: nsdk_nt280h_parameter_kind_t) {
        switch cValue.rawValue {
        case 1:
            self = .bool
        case 2:
            self = .enum
        case 3:
            self = .action
        case 4:
            self = .object
        default:
            self = .unknown
        }
    }
}

extension Se4750ParameterKind {
    init(cValue: nsdk_se4750_parameter_kind_t) {
        switch cValue.rawValue {
        case 1:
            self = .bool
        case 2:
            self = .enum
        case 3:
            self = .uint8
        case 4:
            self = .uint16
        case 5:
            self = .bytesAscii
        default:
            self = .unknown
        }
    }
}

extension Nt212xParameterDefinition {
    init(cValue: nsdk_nt212x_parameter_metadata_t) {
        self.init(
            parameterID: cValue.parameter_id,
            key: stringFromCStringBuffer(cValue.key),
            aliasName: stringFromCStringBuffer(cValue.semantic_name),
            displayName: stringFromCStringBuffer(cValue.display_name),
            symbol: stringFromCStringBuffer(cValue.symbol_name),
            group: stringFromCStringBuffer(cValue.group),
            domainKey: stringFromCStringBuffer(cValue.domain_key),
            familyKey: stringFromCStringBuffer(cValue.family_key),
            sectionKey: stringFromCStringBuffer(cValue.section_key),
            defaultValue: stringFromCStringBuffer(cValue.default_value),
            notes: stringFromCStringBuffer(cValue.notes),
            optionsJSON: stringFromCStringBuffer(cValue.options_json),
            kind: Nt212xParameterKind(cValue: cValue.kind)
        )
    }
}

extension Nt280hParameterDefinition {
    init(cValue: nsdk_nt280h_parameter_metadata_t) {
        self.init(
            parameterID: cValue.parameter_id,
            exID: cValue.ex_id,
            exCMD: cValue.ex_cmd,
            key: stringFromCStringBuffer(cValue.key),
            displayName: stringFromCStringBuffer(cValue.display_name),
            semanticName: stringFromCStringBuffer(cValue.semantic_name),
            symbol: stringFromCStringBuffer(cValue.symbol_name),
            group: stringFromCStringBuffer(cValue.group),
            domainKey: stringFromCStringBuffer(cValue.domain_key),
            familyKey: stringFromCStringBuffer(cValue.family_key),
            sectionKey: stringFromCStringBuffer(cValue.section_key),
            defaultValue: stringFromCStringBuffer(cValue.default_value),
            notes: stringFromCStringBuffer(cValue.notes),
            optionsJSON: stringFromCStringBuffer(cValue.options_json),
            kind: Nt280hParameterKind(cValue: cValue.kind),
            isPlaceholder: cValue.is_placeholder != 0
        )
    }
}

extension Se4750ParameterDefinition {
    init(cValue: nsdk_se4750_parameter_metadata_t) {
        self.init(
            parameterID: cValue.parameter_id,
            key: stringFromCStringBuffer(cValue.key),
            displayName: stringFromCStringBuffer(cValue.display_name),
            semanticName: stringFromCStringBuffer(cValue.semantic_name),
            symbol: stringFromCStringBuffer(cValue.symbol_name),
            group: stringFromCStringBuffer(cValue.group),
            domainKey: stringFromCStringBuffer(cValue.domain_key),
            familyKey: stringFromCStringBuffer(cValue.family_key),
            sectionKey: stringFromCStringBuffer(cValue.section_key),
            defaultValue: stringFromCStringBuffer(cValue.default_value),
            notes: stringFromCStringBuffer(cValue.notes),
            optionsJSON: stringFromCStringBuffer(cValue.options_json),
            kind: Se4750ParameterKind(cValue: cValue.kind)
        )
    }
}

extension Ntc06hSettingDefinition {
    init(cValue: nsdk_ntc06h_setting_metadata_t) {
        var metadata = cValue
        let view = nsdk_ntc06h_setting_metadata_make_view(&metadata)
        self.init(
            key: stringFromCStringPointer(view.key),
            settingCode: stringFromCStringPointer(view.setting_code),
            displayCode: stringFromCStringPointer(view.display_code),
            displayName: stringFromCStringPointer(view.display_name),
            group: stringFromCStringPointer(view.group),
            domainKey: stringFromCStringPointer(view.domain_key),
            familyKey: stringFromCStringPointer(view.family_key),
            sectionKey: stringFromCStringPointer(view.section_key),
            notes: stringFromCStringPointer(view.notes),
            requiresSave: view.requires_save != 0,
            isTemplate: view.is_template != 0,
            templateHint: stringFromCStringPointer(view.template_hint),
            templateExampleCode: stringFromCStringPointer(view.template_example_code),
            templateInputType: Ntc06hTemplateInputType(
                rawValue: stringFromCStringPointer(view.template_input_type)
            ) ?? .none,
            templateInputWidth: Int(view.template_input_width),
            templateInputMin: Int(view.template_input_min),
            templateInputMax: Int(view.template_input_max)
        )
    }
}
