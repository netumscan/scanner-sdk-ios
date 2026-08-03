import Foundation
import XCTest
@testable import ScannerSDK

final class LocalizationTests: XCTestCase {
    func testCatalogResolvesEnglishAndSimplifiedChineseWithoutInitialization() {
        let sdk = ScannerSDK.shared
        XCTAssertEqual(
            Set(sdk.supportedLocales),
            Set(["en", "zh-Hans", "ru", "ja", "ko", "es", "pt", "de", "fr", "it", "el"])
        )
        XCTAssertEqual(
            sdk.localize("nsdk.module_taxonomy.domain.output", fallbackDisplayName: "Fallback", locale: Locale(identifier: "en-US")),
            "Output & Data Format"
        )
        XCTAssertEqual(
            sdk.localize("nsdk.module_taxonomy.domain.output", fallbackDisplayName: "Fallback", locale: Locale(identifier: "zh-CN")),
            "输出与数据格式"
        )
        let expectedByLocale = [
            "ru-RU": "Вывод и формат данных",
            "ja-JP": "出力とデータ形式",
            "ko-KR": "출력 및 데이터 형식",
            "es-ES": "Formato de salida y datos",
            "pt-BR": "Saída e formato de dados",
            "pt-PT": "Saída e formato de dados",
            "de-DE": "Ausgabe- und Datenformat",
            "fr-FR": "Format de sortie et de données",
            "it-IT": "Formato di output e dati",
            "el-GR": "Μορφή εξόδου και δεδομένων",
        ]
        for (identifier, expected) in expectedByLocale {
            XCTAssertEqual(
                sdk.localize(
                    "nsdk.module_taxonomy.domain.output",
                    fallbackDisplayName: "Fallback",
                    locale: Locale(identifier: identifier)
                ),
                expected
            )
        }
        XCTAssertEqual(
            sdk.localize("nsdk.unknown", fallbackDisplayName: "Fallback", locale: Locale(identifier: "ja-JP")),
            "Fallback"
        )
    }

    func testResolverUsesBcp47ParentTagsWithoutMappingTraditionalChineseToSimplifiedChinese() {
        let catalog = [
            "nsdk.parent": [
                "en": "English",
                "sr-Latn": "Latin Serbian",
                "de-DE": "German (Germany)",
            ],
            "nsdk.example": [
                "en": "English",
                "zh-Hans": "简体中文",
            ],
        ]
        XCTAssertEqual(
            ScannerSDK.resolveLocalization(
                catalog,
                localizationKey: "nsdk.parent",
                fallbackDisplayName: "Fallback",
                locale: Locale(identifier: "sr-Latn-RS")
            ),
            "Latin Serbian"
        )
        XCTAssertEqual(
            ScannerSDK.resolveLocalization(
                catalog,
                localizationKey: "nsdk.parent",
                fallbackDisplayName: "Fallback",
                locale: Locale(identifier: "de-DE-u-co-phonebk")
            ),
            "German (Germany)"
        )
        XCTAssertEqual(
            ScannerSDK.resolveLocalization(
                catalog,
                localizationKey: "nsdk.example",
                fallbackDisplayName: "Fallback",
                locale: Locale(identifier: "zh-Hant-TW")
            ),
            "English"
        )
    }
}
