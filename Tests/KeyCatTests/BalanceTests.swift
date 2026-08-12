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

    func testFurnitureCatalogMatchesProvidedAssets() {
        XCTAssertEqual(FurnitureCatalog.all.count, 39)
        XCTAssertEqual(FurnitureCatalog.all.filter { $0.group == .antique }.count, 19)
        XCTAssertEqual(FurnitureCatalog.all.filter { $0.group == .farm }.count, 20)

        for furniture in FurnitureCatalog.all {
            XCTAssertNotNil(
                AppResources.bundle.url(
                    forResource: furniture.resourceName,
                    withExtension: "png",
                    subdirectory: "furniture"
                ),
                "Missing furniture resource: \(furniture.resourceName).png"
            )
            XCTAssertGreaterThan(furniture.purchasePrice, 0)
        }
    }

    func testNavigationUsesAllProvidedAssets() {
        XCTAssertEqual(MapLocation.home.navigationIconResource, "icon_home")
        XCTAssertEqual(MapLocation.field.navigationIconResource, "icon_field")
        XCTAssertEqual(NavigationDirection.left.normalResource, "btn_left_normal")
        XCTAssertEqual(NavigationDirection.left.pressedResource, "btn_left_pressed")
        XCTAssertEqual(NavigationDirection.right.normalResource, "btn_right_normal")
        XCTAssertEqual(NavigationDirection.right.pressedResource, "btn_right_pressed")

        for resourceName in [
            "btn_left_normal", "btn_left_pressed",
            "btn_right_normal", "btn_right_pressed",
            "icon_home", "icon_field",
            "indicator_active", "indicator_inactive"
        ] {
            XCTAssertNotNil(
                AppResources.bundle.url(
                    forResource: resourceName,
                    withExtension: "png",
                    subdirectory: "navigation"
                ),
                "Missing navigation resource: \(resourceName).png"
            )
        }
    }

    func testFurnitureInventoryConsumesAndReturnsItems() {
        guard let furniture = FurnitureCatalog.all.first else {
            return XCTFail("Furniture catalog should not be empty")
        }

        var inventory = FurnitureInventory()
        XCTAssertEqual(inventory.count(of: furniture), 0)
        inventory.add(furniture, quantity: 2)
        XCTAssertEqual(inventory.count(of: furniture), 2)
        XCTAssertTrue(inventory.consume(furniture))
        XCTAssertEqual(inventory.count(of: furniture), 1)
        XCTAssertFalse(inventory.consume(furniture, quantity: 2))
        XCTAssertEqual(inventory.count(of: furniture), 1)
    }

    func testFurnitureInventoryPreventsIntegerOverflowAndRoundTrips() throws {
        guard let furniture = FurnitureCatalog.all.first else {
            return XCTFail("Furniture catalog should not be empty")
        }

        var inventory = FurnitureInventory()
        XCTAssertTrue(inventory.add(furniture, quantity: Int.max))
        XCTAssertFalse(inventory.add(furniture))

        let snapshot = HomeStateSnapshot(home: HomeData(), furnitureInventory: inventory)
        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(HomeStateSnapshot.self, from: encoded)
        XCTAssertEqual(decoded.furnitureInventory.count(of: furniture), Int.max)
    }

    func testHomeDataRejectsInvalidAndOccupiedTiles() {
        var home = HomeData()
        XCTAssertTrue(home.isValid(row: 0, column: 0))
        XCTAssertFalse(home.isValid(row: HomeData.rows, column: 0))
        XCTAssertFalse(home.isOccupied(row: 0, column: 0))

        home.placedFurniture.append(PlacedFurniture(
            furnitureID: FurnitureCatalog.all[0].id,
            row: 0,
            column: 0
        ))
        XCTAssertTrue(home.isOccupied(row: 0, column: 0))
    }

    func testFurnitureCanBeSelectedFromItsVisibleAreaOutsideTheTile() {
        let furniture = FurnitureCatalog.all.first(where: { $0.id == "farm_256_06" })!
        let placed = PlacedFurniture(furnitureID: furniture.id, row: 4, column: 3)
        var home = HomeData()
        home.placedFurniture = [placed]
        let center = CGPoint(
            x: (CGFloat(placed.column) + 0.5) * HomeRoomView.tileSize,
            y: (CGFloat(placed.row) + 0.5) * HomeRoomView.tileSize
        )

        XCTAssertEqual(
            HomeRoomView.placedFurniture(
                in: home,
                at: CGPoint(x: center.x + 50, y: center.y)
            ),
            placed
        )
        XCTAssertNil(HomeRoomView.placedFurniture(
            in: home,
            at: CGPoint(x: center.x + furniture.renderSize, y: center.y)
        ))
    }
}
