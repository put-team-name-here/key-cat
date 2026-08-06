import XCTest
@testable import KeyCat

final class BalanceTests: XCTestCase {
    func testCropGrowthDurationsMatchDisplayedBalance() {
        XCTAssertEqual(SeedKind.carrot.growthDuration, 120)
        XCTAssertEqual(SeedKind.cabbage.growthDuration, 300)
    }

    func testSiameseCatCostsFiftyThousandCoins() {
        XCTAssertEqual(catPurchasePrice("siamese"), 50_000)
        XCTAssertEqual(catPurchasePrice("sphynx"), 10_000)
    }

    func testKoreanAndEnglishTranslationsAreAvailable() {
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .korean), "당근")
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .english), "Carrot")
    }
}
