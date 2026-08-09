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
        XCTAssertEqual(catPurchasePrice("persian"), 500_000)
        XCTAssertEqual(catPurchasePrice("russian_blue"), 250_000)
        XCTAssertEqual(catPurchasePrice("british_shorthair"), 250_000)
    }

    func testCalicoDropsFromCabbageAtConfiguredRate() {
        let calicoRate = catHarvestDropRates(for: .cabbage)
            .first(where: { $0.catID == "calico" })?
            .probability

        XCTAssertEqual(calicoRate, 0.000001)
    }

    func testNewCatCatalogEntriesHaveAllRequiredResources() {
        let newCatIDs = ["persian", "calico", "russian_blue", "british_shorthair"]
        let newCats = CatCatalog.all.filter { newCatIDs.contains($0.id) }

        XCTAssertEqual(Set(newCats.map(\.id)), Set(newCatIDs))
        for cat in newCats {
            let resourceNames = [cat.front, cat.leftSheet, cat.wateringSheet, cat.harvestSheet, "\(cat.id)_idle"]
            for resourceName in resourceNames {
                XCTAssertNotNil(
                    AppResources.bundle.url(forResource: resourceName, withExtension: "png", subdirectory: "cats"),
                    "Missing cat resource: \(resourceName).png"
                )
            }
        }
    }

    func testKoreanAndEnglishTranslationsAreAvailable() {
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .korean), "당근")
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .english), "Carrot")
    }
}
