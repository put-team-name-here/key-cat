import XCTest
@testable import KeyCat

final class BalanceTests: XCTestCase {
    func testCropGrowthDurationsMatchDisplayedBalance() {
        XCTAssertEqual(SeedKind.carrot.growthDuration, 120)
        XCTAssertEqual(SeedKind.cabbage.growthDuration, 300)
        XCTAssertEqual(SeedKind.tomato.growthDuration, 180)
        XCTAssertEqual(SeedKind.peach.growthDuration, 300)
        XCTAssertEqual(SeedKind.durian.growthDuration, 600)
    }

    func testCropPricesAndUnlockRequirementsMatchBalance() {
        XCTAssertEqual(SeedKind.allCases.map(\.purchasePrice), [5, 15, 50, 250, 1_000])
        XCTAssertEqual(CropKind.allCases.map(\.salePrice), [10, 35, 100, 400, 1_400])
        XCTAssertNil(SeedKind.carrot.unlockCatID)
        XCTAssertNil(SeedKind.cabbage.unlockCatID)
        XCTAssertEqual(SeedKind.tomato.unlockCatID, "cheese")
        XCTAssertEqual(SeedKind.peach.unlockCatID, "gray")
        XCTAssertEqual(SeedKind.durian.unlockCatID, "persian")
    }

    func testNewCropResourcesAndGrowthStatesAreComplete() {
        for cropName in ["tomato", "peach", "durian"] {
            for stage in 1...3 {
                XCTAssertNotNil(
                    AppResources.bundle.url(
                        forResource: "\(cropName)_growth_0\(stage)",
                        withExtension: "png",
                        subdirectory: "grounds"
                    )
                )
            }
            for guiResource in [cropName, "\(cropName)_growth_01", "\(cropName)_plus"] {
                XCTAssertNotNil(
                    AppResources.bundle.url(
                        forResource: guiResource,
                        withExtension: "png",
                        subdirectory: "gui"
                    )
                )
            }
        }

        XCTAssertEqual(FieldTileState.tomatoSeed.watered, .wateredTomatoSeed)
        XCTAssertEqual(FieldTileState.wateredPeachSeed.nextGrowthStage, .growingPeach)
        XCTAssertEqual(FieldTileState.growingDurian.matureStage, .matureDurian)
    }

    func testAutoSeedPurchaseQuantityUsesAffordablePartialBatch() {
        XCTAssertEqual(
            AutoSeedPurchasePolicy.quantityToBuy(coins: 45, unitPrice: 15),
            3
        )
        XCTAssertEqual(
            AutoSeedPurchasePolicy.quantityToBuy(coins: 100, unitPrice: 5),
            10
        )
        XCTAssertEqual(
            AutoSeedPurchasePolicy.quantityToBuy(coins: 1_000, unitPrice: 5),
            10
        )
        XCTAssertEqual(
            AutoSeedPurchasePolicy.quantityToBuy(coins: 0, unitPrice: 5),
            0
        )
    }

    func testCatPurchasePricesMatchBalance() {
        XCTAssertEqual(catPurchasePrice("siamese"), 100_000)
        XCTAssertEqual(catPurchasePrice("sphynx"), 50_000)
        XCTAssertEqual(catPurchasePrice("persian"), 500_000)
        XCTAssertEqual(catPurchasePrice("russian_blue"), 250_000)
        XCTAssertEqual(catPurchasePrice("british_shorthair"), 250_000)
    }

    func testRareHarvestCatsUseConfiguredDropRate() {
        let calicoRate = catHarvestDropRates(for: .cabbage)
            .first(where: { $0.catID == "calico" })?
            .probability
        let oddeyeRate = catHarvestDropRates(for: .carrot)
            .first(where: { $0.catID == "oddeye" })?
            .probability

        XCTAssertEqual(calicoRate, 0.00001)
        XCTAssertEqual(oddeyeRate, 0.00001)
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

    func testPersianUsesProvidedWalkingSheet() {
        let persian = CatCatalog.all.first { $0.id == "persian" }
        XCTAssertEqual(persian?.leftSheet, "persian_walk")
        XCTAssertNil(persian?.rightSheet)
    }

    func testKoreanAndEnglishTranslationsAreAvailable() {
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .korean), "당근")
        XCTAssertEqual(L10n.text("당근", "Carrot", language: .english), "Carrot")
    }

    func testCatalogContainsOnlyProvidedToyAssets() {
        XCTAssertEqual(FurnitureCatalog.all.count, 7)
        XCTAssertEqual(FurnitureCatalog.all, FurnitureCatalog.toys)
        XCTAssertFalse(FurnitureCatalog.all.contains { $0.id.hasPrefix("antique_") })
        XCTAssertFalse(FurnitureCatalog.all.contains { $0.id.hasPrefix("farm_") })

        for toy in FurnitureCatalog.all {
            XCTAssertNotNil(
                AppResources.bundle.url(
                    forResource: toy.resourceName,
                    withExtension: "png",
                    subdirectory: "furniture"
                ),
                "Missing toy resource: \(toy.resourceName).png"
            )
            XCTAssertGreaterThan(toy.purchasePrice, 0)
            XCTAssertEqual(toy.renderSize, 72)
        }
    }

    func testToyPricesStayInPremiumTiers() {
        XCTAssertGreaterThanOrEqual(FurnitureCatalog.toys.map(\.purchasePrice).min() ?? 0, 75_000)
    }

    func testToyCatalogPricesAndEffectsMatchBalance() {
        let expected: [String: (price: Int, effect: FurnitureEffect)] = [
            "01_yarn_ball_256": (150_000, .growthSpeedBonus(percent: 5)),
            "02_feather_wand_256": (225_000, .cropSaleBonus(percent: 10)),
            "03_plush_fish_256": (100_000, .cropSaleBonus(percent: 5)),
            "04_toy_mouse_256": (75_000, .typingBonusPerHundred(coins: 100)),
            "05_coil_spring_256": (175_000, .typingBonusPerHundred(coins: 200)),
            "03_cat_bed_256": (250_000, .growthSpeedBonus(percent: 10)),
            "cat_tower_pixelart_256": (250_000, .typingBonusPerHundred(coins: 300)),
        ]

        XCTAssertEqual(Set(FurnitureCatalog.toys.map(\.id)), Set(expected.keys))
        for toy in FurnitureCatalog.toys {
            XCTAssertEqual(toy.purchasePrice, expected[toy.id]?.price)
            XCTAssertEqual(toy.effect, expected[toy.id]?.effect)
            XCTAssertEqual(toy.maximumPurchaseQuantityPerTransaction, 1)
            XCTAssertEqual(toy.maximumOwnedQuantity, 1)
        }
        XCTAssertEqual(FurnitureCatalog.toys.map(\.displayNameKorean), [
            "실뭉치", "낚시대", "인형", "쥐 인형", "스프링", "쿠션", "캣타워"
        ])

        let toy = FurnitureCatalog.toys[0]
        XCTAssertTrue(toy.allowsPurchase(quantity: 1, currentlyOwned: 0))
        XCTAssertFalse(toy.allowsPurchase(quantity: 2, currentlyOwned: 0))
        XCTAssertFalse(toy.allowsPurchase(quantity: 1, currentlyOwned: 1))
    }

    func testPlacedToyBonusesCombineAcrossUniqueToys() {
        let yarn = FurnitureCatalog.item(withID: "01_yarn_ball_256")!
        let wand = FurnitureCatalog.item(withID: "02_feather_wand_256")!
        let fish = FurnitureCatalog.item(withID: "03_plush_fish_256")!
        let mouse = FurnitureCatalog.item(withID: "04_toy_mouse_256")!
        let spring = FurnitureCatalog.item(withID: "05_coil_spring_256")!
        let bed = FurnitureCatalog.item(withID: "03_cat_bed_256")!
        let tower = FurnitureCatalog.item(withID: "cat_tower_pixelart_256")!
        var home = HomeData()
        home.placedFurniture = [
            PlacedFurniture(furnitureID: yarn.id, row: 0, column: 0),
            PlacedFurniture(furnitureID: wand.id, row: 0, column: 1),
            PlacedFurniture(furnitureID: fish.id, row: 0, column: 2),
            PlacedFurniture(furnitureID: mouse.id, row: 0, column: 4),
            PlacedFurniture(furnitureID: spring.id, row: 0, column: 5),
            PlacedFurniture(furnitureID: "unknown-legacy-item", row: 0, column: 6),
            PlacedFurniture(furnitureID: bed.id, row: 1, column: 0),
            PlacedFurniture(furnitureID: tower.id, row: 1, column: 1),
        ]

        XCTAssertEqual(home.activeBonuses, HomeBonusSummary(
            cropSaleBonusPercent: 15,
            growthSpeedBonusPercent: 15,
            typingBonusPerHundred: 600
        ))
    }

    func testPlacedToyBonusesAdjustSaleAndGrowth() {
        let bonuses = HomeBonusSummary(
            cropSaleBonusPercent: 20,
            growthSpeedBonusPercent: 16,
            typingBonusPerHundred: 4
        )

        XCTAssertEqual(bonuses.cropSaleProceeds(unitPrice: 10, quantity: 10), 120)
        XCTAssertEqual(bonuses.cropSaleProceeds(unitPrice: 35, quantity: 2), 84)
        XCTAssertEqual(bonuses.growthDuration(from: 120), 120 / 1.16, accuracy: 0.0001)
    }

    func testNavigationUsesAllProvidedAssets() {
        XCTAssertEqual(MapLocation.allCases, [.home, .field, .expansion])
        XCTAssertEqual(MapLocation.home.next, .field)
        XCTAssertEqual(MapLocation.field.next, .expansion)
        XCTAssertEqual(MapLocation.expansion.previous, .field)
        XCTAssertEqual(MapLocation.home.navigationIconResource, "icon_home")
        XCTAssertEqual(MapLocation.field.navigationIconResource, "icon_field")
        XCTAssertEqual(MapLocation.expansion.navigationIconResource, "icon_field")
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

    func testExpansionPlotsUseIncreasingSequentialPricing() {
        XCTAssertEqual(ExpansionPlotPricing.prices.count, 16)
        XCTAssertEqual(
            ExpansionPlotPricing.prices,
            [
                10_000, 15_000, 25_000, 35_000,
                45_000, 65_000, 85_000, 115_000,
                150_000, 190_000, 235_000, 285_000,
                340_000, 405_000, 480_000, 530_000
            ]
        )
        XCTAssertEqual(ExpansionPlotPricing.price(for: 1), 10_000)
        XCTAssertEqual(ExpansionPlotPricing.price(for: 16), 530_000)
        XCTAssertEqual(ExpansionPlotPricing.prices.reduce(0, +), 3_010_000)
        XCTAssertNil(ExpansionPlotPricing.price(for: 0))
        XCTAssertNil(ExpansionPlotPricing.price(for: 17))

        var expansion = ExpansionFarmData()
        XCTAssertEqual(expansion.nextPlotNumber, 1)
        XCTAssertFalse(expansion.purchaseNext(plotNumber: 2))
        XCTAssertTrue(expansion.purchaseNext(plotNumber: 1))
        XCTAssertEqual(expansion.nextPlotNumber, 2)
        let firstPlot = FarmFieldData.dryGroundCoordinates[0]
        XCTAssertTrue(expansion.isPurchased(row: firstPlot.row, column: firstPlot.column))
        let secondPlot = FarmFieldData.dryGroundCoordinates[1]
        XCTAssertFalse(expansion.isPurchased(row: secondPlot.row, column: secondPlot.column))
    }

    func testPlantingPriorityUsesPreferredSeedBeforeFallback() {
        XCTAssertEqual(
            SeedPlantingPriority.nextSeed(preferred: .peach, available: [.carrot, .peach]),
            .peach
        )
        XCTAssertEqual(
            SeedPlantingPriority.nextSeed(preferred: .peach, available: [.tomato, .cabbage]),
            .cabbage
        )
        XCTAssertNil(SeedPlantingPriority.nextSeed(preferred: .peach, available: []))
    }

    func testFarmCatsAreAssignedPerFarmPageAndTheRestStayHome() {
        let unlocked: Set<String> = ["tuxedo", "cheese", "gray", "persian"]
        let catalog = ["cheese", "gray", "tuxedo", "persian"]
        let initial = FarmCatAssignment.normalized(
            [:],
            unlockedCatIDs: unlocked,
            catalogIDs: catalog
        )

        XCTAssertEqual(initial[.main], "cheese")
        XCTAssertEqual(initial[.expansion], "gray")
        XCTAssertEqual(FarmCatAssignment.homeCatIDs(
            unlockedCatIDs: unlocked,
            assignments: initial,
            catalogIDs: catalog
        ), ["tuxedo", "persian"])

        let swapped = FarmCatAssignment.assigning(
            catID: "cheese",
            to: .expansion,
            current: initial
        )
        XCTAssertEqual(swapped[.main], "gray")
        XCTAssertEqual(swapped[.expansion], "cheese")

        let singleCat: Set<String> = ["tuxedo"]
        let singleAssignment = FarmCatAssignment.normalized(
            [:],
            unlockedCatIDs: singleCat,
            catalogIDs: catalog
        )
        XCTAssertEqual(singleAssignment[.main], "tuxedo")
        XCTAssertNil(singleAssignment[.expansion])
        XCTAssertEqual(FarmCatAssignment.homeCatIDs(
            unlockedCatIDs: singleCat,
            assignments: singleAssignment,
            catalogIDs: catalog
        ), [])
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

    func testLegacyFurnitureIsRemovedWithoutConvertingItToCoins() {
        let toy = FurnitureCatalog.toys[0]
        let removedFurniture = FurnitureItem(
            id: "farm_256_01",
            resourceName: "farm_256_01",
            displayNameKorean: "제거된 가구",
            displayNameEnglish: "Removed Furniture",
            purchasePrice: 9_999
        )
        var inventory = FurnitureInventory()
        XCTAssertTrue(inventory.add(toy, quantity: 3))
        XCTAssertTrue(inventory.add(removedFurniture, quantity: 2))
        let snapshot = HomeStateSnapshot(
            home: HomeData(placedFurniture: [
                PlacedFurniture(furnitureID: toy.id, row: 0, column: 0),
                PlacedFurniture(furnitureID: removedFurniture.id, row: 0, column: 1),
            ]),
            furnitureInventory: inventory
        )

        let migrated = HomeStorage.toysOnly(snapshot)

        XCTAssertEqual(migrated.home.placedFurniture.map(\.furnitureID), [toy.id])
        XCTAssertEqual(migrated.furnitureInventory.count(of: toy), 1)
        XCTAssertEqual(migrated.furnitureInventory.count(of: removedFurniture), 0)
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

    func testToyCanBeSelectedFromItsVisibleAreaOutsideTheTile() {
        let toy = FurnitureCatalog.toys[0]
        let placed = PlacedFurniture(furnitureID: toy.id, row: 4, column: 3)
        var home = HomeData()
        home.placedFurniture = [placed]
        let center = CGPoint(
            x: (CGFloat(placed.column) + 0.5) * HomeRoomView.tileSize,
            y: (CGFloat(placed.row) + 0.5) * HomeRoomView.tileSize
        )

        XCTAssertEqual(
            HomeRoomView.placedFurniture(
                in: home,
                at: CGPoint(x: center.x + 30, y: center.y)
            ),
            placed
        )
        XCTAssertNil(HomeRoomView.placedFurniture(
            in: home,
            at: CGPoint(x: center.x + toy.renderSize, y: center.y)
        ))
    }

    func testHomePointerLocationResolvesToOnlyOneFloorTile() {
        XCTAssertEqual(
            HomeRoomView.tile(at: CGPoint(x: 134, y: 224)),
            FarmTileCoordinate(row: 4, column: 2)
        )
        XCTAssertNil(HomeRoomView.tile(at: CGPoint(x: -1, y: 20)))
        XCTAssertNil(HomeRoomView.tile(at: CGPoint(
            x: CGFloat(HomeData.cols) * HomeRoomView.tileSize,
            y: 20
        )))
    }
}
