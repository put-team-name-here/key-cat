import XCTest
@testable import KeyCat

final class BalanceTests: XCTestCase {
    func testCropGrowthDurationsMatchDisplayedBalance() {
        XCTAssertEqual(SeedKind.carrot.growthDuration, 120)
        XCTAssertEqual(SeedKind.cabbage.growthDuration, 300)
    }

    func testCatPurchasePricesMatchBalance() {
        XCTAssertEqual(catPurchasePrice("siamese"), 100_000)
        XCTAssertEqual(catPurchasePrice("sphynx"), 50_000)
    }

    func testKoreanAndEnglishTranslationsAreAvailable() {
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .korean), "당근")
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .english), "Carrot")
    }
}
