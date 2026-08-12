import SwiftUI
import AppKit

/// GUI PNG asset cache for small overlay status icons.
enum GuiAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let img = cache[name] { return img }
        guard let url = AppResources.bundle.url(forResource: name, withExtension: "png", subdirectory: "gui"),
              let img = NSImage(contentsOf: url) else { return nil }
        cache[name] = img
        return img
    }
}

enum FabricAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let image = cache[name] { return image }
        guard let url = AppResources.bundle.url(forResource: name, withExtension: "png", subdirectory: "fabrics"),
              let image = NSImage(contentsOf: url)
        else { return nil }
        cache[name] = image
        return image
    }
}

/// 도감에 표시할 idle 스프라이트 시트의 첫 프레임 캐시.
enum CatIdleCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let image = cache[name] { return image }
        guard let url = AppResources.bundle.url(forResource: name, withExtension: "png", subdirectory: "cats"),
              let sheet = NSImage(contentsOf: url),
              let cgImage = sheet.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        let side = min(cgImage.width / 3, cgImage.height / 3)
        guard let frame = cgImage.cropping(to: CGRect(x: 0, y: 0, width: side, height: side)) else { return nil }
        let image = NSImage(cgImage: frame, size: NSSize(width: side, height: side))
        cache[name] = image
        return image
    }
}

private struct CodexCatEntry: Identifiable {
    let id: String
    let idleResource: String

    var name: String { localizedCatName(id) }
    var purchasePrice: Int { catPurchasePrice(id) }
}

private let codexCats: [CodexCatEntry] = [
    .init(id: "siamese", idleResource: "siamese_idle"),
    .init(id: "sphynx", idleResource: "sphynx_idle"),
    .init(id: "persian", idleResource: "persian_idle"),
    .init(id: "russian_blue", idleResource: "russian_blue_idle"),
    .init(id: "british_shorthair", idleResource: "british_shorthair_idle"),
    .init(id: "cheese", idleResource: "cheese_idle"),
    .init(id: "tuxedo", idleResource: "tuxedo_idle"),
    .init(id: "oddeye", idleResource: "oddeye_idle"),
    .init(id: "gray", idleResource: "gray_idle"),
    .init(id: "calico", idleResource: "calico_idle"),
]

private let shopCats: [CodexCatEntry] = [
    .init(id: "siamese", idleResource: "siamese_idle"),
    .init(id: "sphynx", idleResource: "sphynx_idle"),
    .init(id: "persian", idleResource: "persian_idle"),
    .init(id: "russian_blue", idleResource: "russian_blue_idle"),
    .init(id: "british_shorthair", idleResource: "british_shorthair_idle"),
]

private enum OnboardingAsset {
    case cat(String)
    case crops
    case catHouse
    case cats([String])
}

private struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let asset: OnboardingAsset
}

private let onboardingPages: [OnboardingPage] = [
    .init(
        id: 0,
        title: L10n.text("고양이가 농사를 지을 수 있어요!", "Cats can farm too!"),
        description: L10n.text(
            "귀여운 고양이와 함께 타이핑 농장을 시작해 보세요.",
            "Start your typing farm with a very capable cat."
        ),
        asset: .cat("tuxedo_idle")
    ),
    .init(
        id: 1,
        title: L10n.text("상점에서 씨앗을 사고 농사를 지어봐요!", "Buy seeds in the shop and start farming!"),
        description: L10n.text(
            "상점 탭에서 당근과 양배추 씨앗을 구매해 밭에 심을 수 있어요.",
            "Buy carrot and cabbage seeds from the Shop tab, then plant them in the field."
        ),
        asset: .crops
    ),
    .init(
        id: 2,
        title: L10n.text("자동모드를 돌려놓으면 5개씩 심어요!", "Auto Mode plants five at a time!"),
        description: L10n.text(
            "5개를 다 심으면 고양이가 집에서 다시 씨앗을 가지러 가요!",
            "After planting five, your cat visits home to fetch more seeds."
        ),
        asset: .catHouse
    ),
    .init(
        id: 3,
        title: L10n.text("특정 확률로 수확 시 새 고양이를 얻을 수 있어요!", "Harvests can unlock new cats!"),
        description: L10n.text(
            "작물을 수확할 때 새로운 고양이를 만날 수도 있어요.",
            "You may meet a new cat when you harvest your crops."
        ),
        asset: .cats(["cheese_idle", "gray_idle", "oddeye_idle"])
    ),
]

/// Simple triangle shape used for pixel-style cat ears.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 오버레이 창 내용. stt-spike RHODES 콘솔 테마 이식.
/// 초미니(고양이) / 축소(상태 카드) / 확장(농장 콘솔) 화면을 전환한다.
struct OverlayView: View {
    @ObservedObject var counter: KeyCounter
    @ObservedObject var state: AppState
    var onToggleSize: () -> Void
    var onMinimize: () -> Void = {}
    var onRestore: () -> Void = {}
    /// "설정" 버튼: 메뉴바 NSMenu 를 popUp (AppDelegate 배선)
    var onOpenSettings: () -> Void = {}
    /// 온보딩 종료 뒤 AppKit 패널 크기를 정상 화면에 맞게 다시 측정한다.
    var onOnboardingFinished: () -> Void = {}

    private let rt = RetroTheme.shared
    private let fp = FarmPixelTheme.shared
    @State private var seedPickerTile: FarmTileCoordinate?
    @State private var selectedCropForSale: CropKind?
    @State private var saleQuantity = 1
    @State private var selectedSeedForPurchase: SeedKind?
    @State private var selectedCatForPurchase: CodexCatEntry?
    @State private var selectedFurnitureForPurchase: FurnitureItem?
    @State private var selectedFurnitureForPlacement: FurnitureItem?
    @State private var selectedPlacedFurnitureForReposition: PlacedFurniture?
    @State private var isHomePlacementModeEnabled = false
    @State private var hoveredHomeTile: FarmTileCoordinate?
    @State private var homePlacementPointer: CGPoint?
    @State private var selectedCodexCat: CodexCatEntry?
    @State private var selectedTypingDate: Date?
    @State private var purchaseQuantity = 1
    @State private var onboardingStep = 0

    var body: some View {
        Group {
            if state.isOnboardingPresented {
                onboardingView
            } else {
                switch state.overlaySizeMode {
                case .compact: compactView
                case .collapsed: collapsedView
                case .expanded: expandedView
                }
            }
        }
    }

    // MARK: - 최초 실행 온보딩

    private var onboardingView: some View {
        VStack(spacing: 11) {
            VStack(spacing: 4) {
                Text(L10n.text("KEYCAT 시작하기", "GET STARTED WITH KEYCAT"))
                    .font(galmuriFont(18))
                    .foregroundColor(fp.border)
                Text(L10n.text("아래 내용을 순서대로 눌러 보세요", "Tap each card in order to learn the basics"))
                    .font(galmuriFont(10))
                    .foregroundColor(fp.inkDim)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 4) {
                ForEach(onboardingPages) { page in
                    Rectangle()
                        .fill(page.id < onboardingStep ? fp.primary : fp.cell)
                        .frame(height: 5)
                        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 1))
                }
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 7) {
                    ForEach(onboardingPages) { page in
                        onboardingStepCard(page)
                    }
                }
                .padding(.vertical, 1)
            }

            popupActionButton(
                L10n.text("확인", "OK"),
                enabled: onboardingStep == onboardingPages.count,
                action: finishOnboarding
            )
        }
        .padding(14)
        .frame(width: 352, height: 580)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .accessibilityElement(children: .contain)
    }

    private func onboardingStepCard(_ page: OnboardingPage) -> some View {
        let isCurrent = page.id == onboardingStep
        let isCompleted = page.id < onboardingStep
        return Button(action: { advanceOnboarding(to: page.id) }) {
            HStack(spacing: 9) {
                ZStack {
                    Rectangle()
                        .fill(isCompleted ? fp.primary : (isCurrent ? fp.primary.opacity(0.2) : fp.cell))
                        .frame(width: 25, height: 25)
                        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 2))
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(fp.primaryText)
                    } else {
                        Text("\(page.id + 1)")
                            .font(galmuriFont(11))
                            .foregroundColor(fp.border)
                    }
                }

                onboardingAsset(page.asset)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(page.title)
                        .font(galmuriFont(11))
                        .foregroundColor(fp.border)
                        .multilineTextAlignment(.leading)
                    Text(page.description)
                        .font(galmuriFont(9))
                        .foregroundColor(fp.inkDim)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Image(systemName: isCompleted ? "checkmark.circle.fill" : (isCurrent ? "chevron.right" : "lock.fill"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isCompleted ? fp.primary : (isCurrent ? fp.border : fp.inkDim))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
            .background(isCurrent || isCompleted ? fp.cell : fp.cell.opacity(0.65))
            .overlay(Rectangle().strokeBorder(isCurrent ? fp.primary : fp.border, lineWidth: isCurrent ? 3 : 2))
        }
        .buttonStyle(.plain)
        .disabled(!isCurrent)
        .accessibilityLabel(page.title)
        .accessibilityHint(
            isCurrent
                ? L10n.text("눌러서 다음 단계로 이동", "Tap to continue")
                : (isCompleted ? L10n.text("완료됨", "Completed") : L10n.text("앞 단계부터 완료하세요", "Complete the previous steps first"))
        )
    }

    @ViewBuilder
    private func onboardingAsset(_ asset: OnboardingAsset) -> some View {
        switch asset {
        case .cat(let resource):
            if let image = CatIdleCache.image(resource) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(3)
            } else {
                catIcon
            }
        case .crops:
            HStack(spacing: 2) {
                cropImage("carrot_growth_01", fallbackColor: fp.carrot, size: 24)
                cropImage("cabbage_growth_01", fallbackColor: fp.cabbage, size: 24)
            }
        case .catHouse:
            if let image = FabricAssetCache.image("cat_house") {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(2)
            } else {
                Image(systemName: "house.fill")
                    .font(.system(size: 28))
                    .foregroundColor(fp.inkDim)
            }
        case .cats(let resources):
            HStack(spacing: 1) {
                ForEach(resources, id: \.self) { resource in
                    if let image = CatIdleCache.image(resource) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    }
                }
            }
            .padding(2)
        }
    }

    private func advanceOnboarding(to step: Int) {
        guard step == onboardingStep else { return }
        onboardingStep += 1
    }

    private func finishOnboarding() {
        guard onboardingStep == onboardingPages.count else { return }
        state.completeOnboarding()
        onOnboardingFinished()
    }

    // MARK: - 초미니 화면 (정사각형 잔디 + 고양이)

    private var compactView: some View {
        ZStack(alignment: .topTrailing) {
            GrassBackground(tileSize: 44)
            WalkingCat(character: state.selectedCat, spriteSize: 68, fps: 9, speed: 24)

            Button(action: onRestore) {
                guiControlIcon("zoom_in", size: 18)
                    .frame(width: 29, height: 29)
                    .background(rt.panel)
                    .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("위젯 크게 보기", "Enlarge widget"))
            .padding(5)
        }
        .frame(width: 116, height: 116)
        .overlay(alignment: .bottomTrailing) {
            Button(action: state.cycleCat) {
                guiControlIcon("change", size: 21)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(rt.yellow))
                    .overlay(Circle().strokeBorder(rt.ink, lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.25), radius: 0, x: 2, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("고양이 변경", "Change cat"))
            .padding(5)
        }
        .padding(8)
        .frame(width: 132, height: 132)
        .background(rt.cardBg)
        .clipped()
        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
        .fixedSize()
    }

    // MARK: - 축소 화면 (레트로 픽셀 카드, 시안 축소화면.dc.html)

    private var collapsedView: some View {
        HStack(alignment: .top, spacing: 14) {
            catColumn
            statsColumn
        }
        .padding(14)
        .frame(width: 352, alignment: .topLeading)
        .background(rt.cardBg)
        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
        .fixedSize()
    }

    // MARK: 좌측 - 고양이 박스 + "변경" 버튼

    private var catColumn: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                GrassBackground()
                WalkingCat(character: state.selectedCat, spriteSize: 60, fps: 9)
            }
            .frame(width: 118, height: 118)
            .clipped()
            .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))

            Button(action: state.cycleCat) {
                guiControlIcon("change", size: 24)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(rt.yellow))
                    .overlay(Circle().strokeBorder(rt.ink, lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.25), radius: 0, x: 2, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("고양이 변경", "Change cat"))
            .offset(x: 10, y: 10)
        }
        .frame(width: 118, height: 118, alignment: .topLeading)
    }

    // MARK: 우측 - 상단 버튼행 + 정보 타일

    private var statsColumn: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Spacer(minLength: 0)

                Button(action: onMinimize) {
                    guiControlIcon("zoom_out", size: 17)
                        .frame(width: 29, height: 27)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("작게 보기", "Make widget smaller"))

                Button(action: onToggleSize) {
                    guiControlIcon("zoom_in", size: 17)
                        .frame(width: 29, height: 27)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("농장 크게 보기", "Open full farm"))

                Button(action: onOpenSettings) {
                    guiControlIcon("setting", size: 17)
                        .frame(width: 29, height: 27)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: false, vertical: true)

            infoTile {
                keyboardGlyph
                Spacer(minLength: 0)
                Text(L10n.characters(counter.count))
                    .font(galmuriFont(14)).foregroundColor(rt.text)
            }

            infoTile {
                coinGlyph
                Spacer(minLength: 0)
                Text("\(state.coins)")
                    .font(galmuriFont(14)).foregroundColor(rt.text)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func infoTile<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8, content: content)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(rt.panel)
            .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
    }

    /// Resources/gui/key_cap_2.png 기반 타자 수 아이콘. 리소스 누락 시 기존 픽셀 아이콘으로 폴백.
    @ViewBuilder private var keyboardGlyph: some View {
        if let img = GuiAssetCache.image("key_cap_2") {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityLabel(L10n.text("타자 수", "Keystroke count"))
        } else {
            legacyKeyboardGlyph
        }
    }

    /// Resources/gui/coin_2.png 기반 보유 코인 아이콘. 리소스 누락 시 기존 픽셀 아이콘으로 폴백.
    @ViewBuilder private var coinGlyph: some View {
        if let img = GuiAssetCache.image("coin_2") {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityLabel(L10n.text("보유 코인", "Coins owned"))
        } else {
            legacyCoinGlyph
        }
    }

    /// 폴백용 핑크 키보드 픽셀 아이콘 (20x18, 키 3개)
    private var legacyKeyboardGlyph: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(rt.pink)
            pixel(x: 3, y: 4, w: 4, h: 4, color: rt.pinkKey)
            pixel(x: 10, y: 4, w: 4, h: 4, color: rt.pinkKey)
            pixel(x: 3, y: 10, w: 11, h: 4, color: rt.pinkKey)
        }
        .frame(width: 20, height: 18)
        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 2))
    }

    /// 폴백용 노란 코인 픽셀 아이콘 (18x18 원, 눈2 + 입)
    private var legacyCoinGlyph: some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(rt.yellow)
            pixel(x: 4, y: 5, w: 3, h: 4, color: rt.ink)
            pixel(x: 10, y: 5, w: 3, h: 4, color: rt.ink)
            pixel(x: 6, y: 10, w: 6, h: 3, color: rt.ink)
        }
        .frame(width: 18, height: 18)
        .overlay(Circle().strokeBorder(rt.ink, lineWidth: 2))
    }

    /// topLeading 기준 오프셋 픽셀 사각형 (시안 절대좌표 재현)
    private func pixel(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: w, height: h)
            .offset(x: x, y: y)
    }

    // MARK: - 확장 화면 (농장 콘솔, 시안 농장앱화면.dc.html)

    private var expandedView: some View {
        VStack(spacing: 0) {
            mapView
            resourceBar
            inventorySection
            tabBar
        }
        .frame(width: 360)
        .background(fp.panel)
        .overlay {
            if let notice = state.catUnlockNotices.first,
               let cat = codexCats.first(where: { $0.id == notice.catID }) {
                ZStack {
                    Color.black.opacity(0.4)
                    catUnlockPopup(notice: notice, cat: cat)
                }
            } else if let crop = selectedCropForSale {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCropForSale = nil }
                    salePopup(for: crop)
                }
            } else if let seed = selectedSeedForPurchase {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedSeedForPurchase = nil }
                    seedPurchasePopup(for: seed)
                }
            } else if let cat = selectedCatForPurchase {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCatForPurchase = nil }
                    catPurchasePopup(for: cat)
                }
            } else if let furniture = selectedFurnitureForPurchase {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedFurnitureForPurchase = nil }
                    furniturePurchasePopup(for: furniture)
                }
            } else if let cat = selectedCodexCat {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCodexCat = nil }
                    codexCatPopup(for: cat)
                }
            } else if let date = selectedTypingDate {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTypingDate = nil }
                    typingRecordPopup(for: date)
                }
            }
        }
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .fixedSize()
    }

    private var mapView: some View {
        Group {
            switch state.selectedMapLocation {
            case .field:
                farmField
            case .home:
                homeField
            }
        }
    }

    // MARK: 밭 필드 - 잔디 배경 + 우상단 축소/설정 버튼

    private var farmField: some View {
        ZStack(alignment: .topLeading) {
            FarmFieldGrassView(field: state.farmField) { row, column in
                seedPickerTile = FarmTileCoordinate(row: row, column: column)
            }
            catHouse
            WalkingCat(
                character: state.selectedCat,
                spriteSize: 70.4,
                fps: 9,
                speed: 34,
                farmTask: state.farmWorkQueue.first,
                harvestRewardImageName: currentHarvestRewardImageName,
                onFarmTaskComplete: state.completeFarmWork
            )
                .allowsHitTesting(false)
            mapNavigation
            fieldControls
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .topTrailing)

            if let tile = seedPickerTile {
                seedPicker(for: tile)
                    .position(seedPickerPosition(for: tile))
                    .zIndex(1)
            }
        }
        .frame(height: 540)
        .clipped()
    }

    private var homeField: some View {
        ZStack(alignment: .topLeading) {
            HomeRoomView(
                home: state.home,
                selectedFurniture: selectedFurnitureForPlacement,
                selectedPlacedFurniture: selectedPlacedFurnitureForReposition,
                hoveredTile: hoveredHomeTile,
                pointerLocation: homePlacementPointer
            )
            .zIndex(0)

            if !isHomePlacementModeEnabled,
               activeFurniturePlacement == nil {
                homePlacementLockedSurface
                    .zIndex(4)
            }

            if isHomePlacementModeEnabled,
               selectedFurnitureForPlacement == nil,
               selectedPlacedFurnitureForReposition == nil {
                homeFurnitureInteractionLayer
                    .zIndex(5)
            }

            if activeFurniturePlacement != nil {
                homePlacementSurface
                    .zIndex(6)
            }

            mapNavigation
                .zIndex(10)

            homePlacementModeButton
                .zIndex(11)

            fieldControls
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .zIndex(20)

            if let furniture = selectedFurnitureForPlacement {
                furniturePlacementHint(furniture, isRepositioning: false)
                    .position(x: 180, y: 28)
                    .zIndex(21)
            } else if let placedFurniture = selectedPlacedFurnitureForReposition,
                      let furniture = FurnitureCatalog.item(withID: placedFurniture.furnitureID) {
                furniturePlacementHint(furniture, isRepositioning: true)
                    .position(x: 180, y: 28)
                    .zIndex(21)
            }
        }
        .frame(height: 540)
        .clipped()
    }

    /// 배치 모드에서만 가구의 실제 표시 영역을 선택 대상으로 사용한다.
    private var homeFurnitureInteractionLayer: some View {
        HomePointerTrackingView(
            onPointerMove: updateHomePlacementPointer,
            onPointerExit: clearHomePlacementPointer,
            onTap: { point in
                updateHomePlacementPointer(point)
                guard let placedFurniture = HomeRoomView.placedFurniture(
                    in: state.home,
                    at: point
                )
                else { return }
                selectPlacedFurnitureForReposition(placedFurniture)
            }
        )
        .accessibilityLabel(L10n.text(
            "가구를 선택해 재배치",
            "Select furniture to reposition"
        ))
    }

    @ViewBuilder private var homePlacementModeButton: some View {
        if isHomePlacementModeEnabled {
            HStack(spacing: 6) {
                homePlacementControl(
                    title: L10n.text("완료", "Done"),
                    systemImage: "checkmark",
                    background: fp.primary,
                    action: toggleHomePlacementMode,
                    accessibilityLabel: L10n.text("가구 배치 모드 완료", "Finish furniture placement mode")
                )

                if selectedPlacedFurnitureForReposition != nil {
                    homePlacementControl(
                        title: L10n.text("창고", "Storage"),
                        systemImage: "archivebox",
                        background: fp.cell,
                        action: returnSelectedPlacedFurniture,
                        accessibilityLabel: L10n.text("선택한 가구를 창고로 이동", "Move selected furniture to storage")
                    )
                }
            }
            .position(
                x: selectedPlacedFurnitureForReposition == nil ? 60 : 112,
                y: 503
            )
        } else {
            homePlacementControl(
                title: L10n.text("배치 모드", "Placement"),
                systemImage: "square.and.pencil",
                background: fp.panel,
                action: toggleHomePlacementMode,
                accessibilityLabel: L10n.text("가구 배치 모드 시작", "Start furniture placement mode")
            )
            .position(x: 60, y: 503)
        }
    }

    /// 배치 중인 주요 조작은 함께 보이며, 기존 완료 버튼보다 1.5배 높은 33pt를 유지한다.
    private func homePlacementControl(
        title: String,
        systemImage: String,
        background: Color,
        action: @escaping () -> Void,
        accessibilityLabel: String
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(galmuriFont(10))
            }
            .foregroundColor(fp.border)
            .frame(width: 92, height: 33)
            .background(background)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    /// 일반 집 화면에서는 바닥을 클릭해도 가구 편집으로 이어지지 않게 막는다.
    /// 내비게이션과 배치 모드 버튼은 더 높은 레이어에서 계속 동작한다.
    private var homePlacementLockedSurface: some View {
        HomePointerTrackingView(
            onPointerMove: { _ in },
            onPointerExit: {},
            onTap: { _ in }
        )
        .accessibilityHidden(true)
    }

    /// 칸 전체 격자 대신 포인터가 머무는 바닥과 흰색 가구 실루엣만 보여 주는 배치 입력면.
    private var homePlacementSurface: some View {
        HomePointerTrackingView(
            onPointerMove: updateHomePlacementPointer,
            onPointerExit: clearHomePlacementPointer,
            onTap: { point in
                updateHomePlacementPointer(point)
                guard let tile = HomeRoomView.tile(at: point) else { return }
                placeSelectedFurniture(at: tile)
            }
        )
        .onDisappear(perform: clearHomePlacementPointer)
        .accessibilityLabel(L10n.text(
            "가구 배치 위치",
            "Furniture placement position"
        ))
    }

    private var activeFurniturePlacement: FurnitureItem? {
        if let selectedFurnitureForPlacement {
            return selectedFurnitureForPlacement
        }
        guard let placedFurniture = selectedPlacedFurnitureForReposition else { return nil }
        return FurnitureCatalog.item(withID: placedFurniture.furnitureID)
    }

    private var mapNavigation: some View {
        GeometryReader { geometry in
            mapDestinationButton(.home, direction: .left)
                .position(x: 29, y: geometry.size.height / 2)
            mapDestinationButton(.field, direction: .right)
                .position(x: geometry.size.width - 29, y: geometry.size.height / 2)

            HStack(spacing: 3) {
                navigationIndicator(isCurrent: state.selectedMapLocation == .home)
                navigationIndicator(isCurrent: state.selectedMapLocation == .field)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height - 14)
            .allowsHitTesting(false)
        }
    }

    private func mapDestinationButton(
        _ location: MapLocation,
        direction: NavigationDirection
    ) -> some View {
        Button(action: { navigate(to: location) }) {
            if let image = NavigationAssetCache.image(location.navigationIconResource) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: location == .field ? "leaf.fill" : "house.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(fp.border)
                    .frame(width: 22, height: 22)
            }
        }
        .buttonStyle(NavigationAssetButtonStyle(direction: direction))
        .disabled(state.selectedMapLocation == location)
        .accessibilityLabel(L10n.text(
            "\(location.displayName)(으)로 이동",
            "Go to \(location.displayName)"
        ))
    }

    private func navigationIndicator(isCurrent: Bool) -> some View {
        // 제공된 스프라이트는 이름과 달리 밝은 점이 indicator_inactive다.
        // 현재 위치를 흰색으로 보여 주기 위해 밝은 점을 현재 페이지에 쓴다.
        let resource = isCurrent ? "indicator_inactive" : "indicator_active"
        return Group {
            if let image = NavigationAssetCache.image(resource) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Circle()
                    .fill(isCurrent ? fp.cell : fp.primary)
                    .overlay(Circle().strokeBorder(fp.border, lineWidth: 1.5))
            }
        }
        .frame(width: 12, height: 12)
        .accessibilityHidden(true)
    }

    private func furniturePlacementHint(
        _ furniture: FurnitureItem,
        isRepositioning: Bool
    ) -> some View {
        HStack(spacing: 5) {
            FurnitureAssetImage(furniture: furniture, size: 25)
            Text(L10n.text(
                isRepositioning
                    ? "마우스로 \(furniture.displayName) 위치를 정하세요"
                    : "마우스로 \(furniture.displayName) 놓을 위치를 정하세요",
                isRepositioning
                    ? "Move the mouse to position \(furniture.displayName)"
                    : "Move the mouse to place \(furniture.displayName)"
            ))
                .font(galmuriFont(9))
                .foregroundColor(fp.border)
            Button(action: cancelFurniturePlacement) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(fp.border)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 2))
    }

    private func placeSelectedFurniture(at tile: FarmTileCoordinate) {
        if let furniture = selectedFurnitureForPlacement {
            if state.placeFurniture(furniture, at: tile) {
                selectedFurnitureForPlacement = nil
                clearHomePlacementPointer()
            }
        } else if let placedFurniture = selectedPlacedFurnitureForReposition,
                  state.moveFurniture(placedFurniture, to: tile) {
            selectedPlacedFurnitureForReposition = nil
            clearHomePlacementPointer()
        }
    }

    private func selectPlacedFurnitureForReposition(_ placedFurniture: PlacedFurniture) {
        guard isHomePlacementModeEnabled,
              FurnitureCatalog.item(withID: placedFurniture.furnitureID) != nil
        else { return }
        selectedFurnitureForPlacement = nil
        selectedPlacedFurnitureForReposition = placedFurniture
        state.selectedMapLocation = .home
    }

    private func returnSelectedPlacedFurniture() {
        guard let placedFurniture = selectedPlacedFurnitureForReposition else { return }
        if state.returnFurnitureToStorage(placedFurniture) {
            selectedPlacedFurnitureForReposition = nil
            clearHomePlacementPointer()
        }
    }

    private func cancelFurniturePlacement() {
        selectedFurnitureForPlacement = nil
        selectedPlacedFurnitureForReposition = nil
        clearHomePlacementPointer()
    }

    private func toggleHomePlacementMode() {
        if isHomePlacementModeEnabled {
            cancelFurniturePlacement()
            isHomePlacementModeEnabled = false
        } else {
            isHomePlacementModeEnabled = true
        }
    }

    private func clearHomePlacementPointer() {
        hoveredHomeTile = nil
        homePlacementPointer = nil
    }

    private func updateHomePlacementPointer(_ point: CGPoint) {
        homePlacementPointer = point
        hoveredHomeTile = HomeRoomView.tile(at: point)
    }

    private func navigate(to location: MapLocation) {
        if location != .home {
            cancelFurniturePlacement()
            isHomePlacementModeEnabled = false
        }
        state.selectedMapLocation = location
    }

    /// 현재 수확 작업의 작물에 맞는 머리 위 보상 이미지.
    private var currentHarvestRewardImageName: String? {
        guard let task = state.farmWorkQueue.first,
              task.kind == .harvesting,
              state.farmField.isValid(row: task.tile.row, column: task.tile.column)
        else { return nil }
        let tileState = state.farmField.tiles[state.farmField.index(
            row: task.tile.row,
            column: task.tile.column
        )].state
        switch tileState {
        case .matureCarrot: return "carrot_plus"
        case .matureCabbage: return "cabbage_plus"
        default: return nil
        }
    }

    /// 밭 그리드 (x: 6, y: 3)에 배치한 고양이집.
    @ViewBuilder private var catHouse: some View {
        if let image = FabricAssetCache.image("cat_house") {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 110, height: 110)
                .position(
                    x: (CGFloat(FarmFieldData.catHouseCoordinate.column) + 0.5) * 45,
                    y: (CGFloat(FarmFieldData.catHouseCoordinate.row) + 0.5) * 45
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// 선택한 45pt 밭 타일 바로 위에 씨앗 선택 패널의 중심을 둔다.
    private func seedPickerPosition(for tile: FarmTileCoordinate) -> CGPoint {
        let tileSize: CGFloat = 45
        let pickerWidth: CGFloat = 176
        let tileCenterX = (CGFloat(tile.column) + 0.5) * tileSize
        let clampedX = min(max(tileCenterX, pickerWidth / 2 + 6), 360 - pickerWidth / 2 - 6)
        let tileTop = CGFloat(tile.row) * tileSize
        return CGPoint(x: clampedX, y: tileTop - 49)
    }

    private func seedPicker(for tile: FarmTileCoordinate) -> some View {
        let ownedSeeds = SeedKind.allCases.filter { state.seedCount($0) > 0 }
        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(L10n.text("심을 씨앗", "Choose seeds"))
                    .font(galmuriFont(12))
                    .foregroundColor(fp.border)
                Spacer(minLength: 0)
                Button(action: { seedPickerTile = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(fp.border)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
            }

            if ownedSeeds.isEmpty {
                Text(L10n.text("창고에 보유한 씨앗이 없어요", "There are no seeds in storage"))
                    .font(galmuriFont(9))
                    .foregroundColor(fp.inkDim)
                    .padding(.vertical, 5)
            } else {
                ForEach(ownedSeeds) { seed in
                    Button(action: { selectSeed(seed, for: tile) }) {
                        HStack(spacing: 7) {
                            sproutIcon(seedColor(seed))
                            Text(seed.displayName)
                                .font(galmuriFont(10))
                                .foregroundColor(fp.border)
                            Spacer(minLength: 0)
                            Text(L10n.count(state.seedCount(seed)))
                                .font(galmuriFont(9))
                                .foregroundColor(fp.inkDim)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(fp.cell)
                        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(9)
        .frame(width: 176)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .offset(x: 4, y: 4)
        )
    }

    private func selectSeed(_ seed: SeedKind, for tile: FarmTileCoordinate) {
        if state.plant(seed, at: tile) {
            seedPickerTile = nil
        }
    }

    private var fieldControls: some View {
        HStack(spacing: 6) {
            Button(action: onToggleSize) {
                guiControlIcon("zoom_out", size: 18)
                    .frame(width: 30, height: 30)
                    .background(fp.cell)
                    .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
            }
            .buttonStyle(.plain)

            Button(action: onOpenSettings) {
                guiControlIcon("setting", size: 18)
                    .frame(width: 30, height: 30)
                    .background(fp.cell)
                    .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func guiControlIcon(_ resource: String, size: CGFloat) -> some View {
        if let image = GuiAssetCache.image(resource) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    // MARK: 자원 바 - 기록 글자 수 + 보유 코인

    private var resourceBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(fp.border).frame(height: 3)
            HStack(spacing: 12) {
                keyboardGlyph
                Text(L10n.characters(counter.count))
                    .font(galmuriFont(15)).foregroundColor(fp.barText)
                Spacer(minLength: 0)
                Text("|").foregroundColor(fp.barDim)
                Spacer(minLength: 0)
                coinGlyph
                Text("\(state.coins)")
                    .font(galmuriFont(15)).foregroundColor(fp.barText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(fp.bar)
            Rectangle().fill(fp.border).frame(height: 3)
        }
    }

    // MARK: 인벤토리/도감 - 하단 탭에 따라 상점과 같은 틀로 전환

    private var inventorySection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                inventoryContent
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .frame(height: 218, alignment: .topLeading)
        .clipped()
    }

    @ViewBuilder private var inventoryContent: some View {
        switch state.selectedFarmTab {
        case .shop:
            shopContent
        case .codex:
            codexContent
        case .storage:
            storageContent
        case .log:
            logContent
        }
    }

    private var shopContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(ShopCategory.allCases) { category in
                    shopCategoryButton(category)
                }
            }
            itemGrid {
                switch state.selectedShopCategory {
                case .seeds:
                    shopSeedItem(.carrot)
                    shopSeedItem(.cabbage)
                    ForEach(0..<6, id: \.self) { _ in emptySlot }
                case .cats:
                    ForEach(shopCats) { cat in
                        shopCatItem(cat)
                    }
                    ForEach(0..<6, id: \.self) { _ in emptySlot }
                case .furniture:
                    ForEach(FurnitureCatalog.all) { furniture in
                        shopFurnitureItem(furniture)
                    }
                }
            }
        }
    }

    private var storageContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(StorageCategory.allCases) { category in
                    storageCategoryButton(category)
                }
            }

            switch state.selectedStorageCategory {
            case .seeds:
                itemGrid {
                    ForEach(SeedKind.allCases) { seed in
                        storedSeedItem(seed)
                    }
                    ForEach(0..<max(0, 8 - SeedKind.allCases.count), id: \.self) { _ in emptySlot }
                }
            case .crops:
                let ownedCrops = CropKind.allCases.filter { state.cropCount($0) > 0 }
                itemGrid {
                    ForEach(ownedCrops) { crop in
                        storedCropItem(crop)
                    }
                    ForEach(0..<max(0, 8 - ownedCrops.count), id: \.self) { _ in emptySlot }
                }
            case .furniture:
                let ownedFurniture = FurnitureCatalog.all.filter { state.furnitureCount($0) > 0 }
                itemGrid {
                    ForEach(ownedFurniture) { furniture in
                        storedFurnitureItem(furniture)
                    }
                    ForEach(0..<max(0, 8 - ownedFurniture.count), id: \.self) { _ in emptySlot }
                }
            }
        }
    }

    private var codexContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(CodexCategory.allCases) { category in
                    codexCategoryButton(category)
                }
            }

            itemGrid {
                switch state.selectedCodexCategory {
                case .crops:
                    cropEntry(.carrot)
                    cropEntry(.cabbage)
                    ForEach(0..<6, id: \.self) { _ in emptySlot }
                case .cats:
                    ForEach(codexCats) { cat in
                        catEntry(cat)
                    }
                    ForEach(0..<max(0, 8 - codexCats.count), id: \.self) { _ in emptySlot }
                }
            }
        }
    }

    private var logContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(currentMonthTitle)
                    .font(galmuriFont(14))
                    .foregroundColor(fp.border)
                Spacer(minLength: 0)
                Text(L10n.text(
                    "연속 \(currentTypingStreak)일 · 이번 달 \(currentMonthTypingCount)타",
                    "\(currentTypingStreak)-day streak · \(currentMonthTypingCount) keys this month"
                ))
                    .font(galmuriFont(11))
                    .foregroundColor(fp.inkDim)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(24), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(currentMonthDates, id: \.self) { date in
                    typingStreakCell(for: date)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(fp.cell)

            HStack(spacing: 4) {
                Text(L10n.text("적음", "Less"))
                    .font(galmuriFont(8))
                    .foregroundColor(fp.inkDim)
                ForEach([0, 50, 250, 750, 1500], id: \.self) { count in
                    Rectangle()
                        .fill(streakColor(for: count))
                        .frame(width: 11, height: 11)
                        .overlay(Rectangle().strokeBorder(fp.border.opacity(0.35), lineWidth: 1))
                }
                Text(L10n.text("많음", "More"))
                    .font(galmuriFont(8))
                    .foregroundColor(fp.inkDim)
                Spacer(minLength: 0)
                Text(L10n.text("날짜를 눌러 확인", "Select a date"))
                    .font(galmuriFont(8))
                    .foregroundColor(fp.inkDim)
            }
        }
    }

    private var currentMonthNumber: Int {
        Calendar.current.component(.month, from: Date())
    }

    private var currentMonthTitle: String {
        guard AppLanguage.current == .english else { return "\(currentMonthNumber)월 기록" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return "\(formatter.string(from: Date())) Log"
    }

    private var currentMonthTypingCount: Int {
        currentMonthDates.reduce(0) { $0 + counter.count(on: $1) }
    }

    /// 이번 달 1일부터 마지막 날까지만 스트릭 셀로 표시한다.
    private var currentMonthDates: [Date] {
        let calendar = Calendar.current
        guard let month = calendar.dateInterval(of: .month, for: Date()),
              let dayCount = calendar.range(of: .day, in: .month, for: month.start)?.count
        else { return [] }
        return (0..<dayCount).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: month.start)
        }
    }

    private var currentTypingStreak: Int {
        let calendar = Calendar.current
        var cursor = calendar.startOfDay(for: Date())
        if counter.count(on: cursor) == 0,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }
        var streak = 0
        while counter.count(on: cursor) > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }
        return streak
    }

    @ViewBuilder private func typingStreakCell(for date: Date) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        if date > today {
            Color.clear.frame(width: 24, height: 24)
        } else {
            let typingCount = counter.count(on: date)
            Button(action: { selectedTypingDate = date }) {
                Rectangle()
                    .fill(streakColor(for: typingCount))
                    .frame(width: 24, height: 24)
                    .overlay(Rectangle().strokeBorder(fp.border.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(typingDateText(date)), \(L10n.keystrokes(typingCount))")
        }
    }

    private func streakColor(for count: Int) -> Color {
        let green = Color(red: 0.24, green: 0.62, blue: 0.32)
        switch count {
        case 0: return fp.cell
        case 1..<100: return green.opacity(0.28)
        case 100..<500: return green.opacity(0.48)
        case 500..<1_000: return green.opacity(0.72)
        default: return green
        }
    }

    private func typingDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguage.current == .korean ? "ko_KR" : "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMM d EEE")
        return formatter.string(from: date)
    }

    private func typingRecordPopup(for date: Date) -> some View {
        let typingCount = counter.count(on: date)
        return VStack(spacing: 16) {
            popupHeader(L10n.text("타자 기록", "Typing Log")) { selectedTypingDate = nil }
            Rectangle()
                .fill(streakColor(for: typingCount))
                .frame(width: 48, height: 48)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
            Text(typingDateText(date))
                .font(galmuriFont(13))
                .foregroundColor(fp.border)
            Text(L10n.keystrokes(typingCount))
                .font(galmuriFont(22))
                .foregroundColor(fp.border)
            popupActionButton(L10n.text("확인", "OK"), enabled: true) {
                selectedTypingDate = nil
            }
        }
        .padding(18)
        .frame(width: 250)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(Rectangle().fill(Color.black.opacity(0.3)).offset(x: 5, y: 5))
    }

    private func categoryPill(_ title: String) -> some View {
        Text(title)
            .font(galmuriFont(14))
            .foregroundColor(fp.border)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
    }

    private func codexCategoryButton(_ category: CodexCategory) -> some View {
        let active = state.selectedCodexCategory == category
        return Button(action: { state.selectedCodexCategory = category }) {
            Text(category.displayName)
                .font(galmuriFont(14))
                .foregroundColor(active ? fp.primaryText : fp.border)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(active ? fp.primary : fp.cell)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
    }

    private func shopCategoryButton(_ category: ShopCategory) -> some View {
        let active = state.selectedShopCategory == category
        return Button(action: { state.selectedShopCategory = category }) {
            Text(category.displayName)
                .font(galmuriFont(14))
                .foregroundColor(active ? fp.primaryText : fp.border)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(active ? fp.primary : fp.cell)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
    }

    private func storageCategoryButton(_ category: StorageCategory) -> some View {
        let active = state.selectedStorageCategory == category
        return Button(action: { state.selectedStorageCategory = category }) {
            Text(category.displayName)
                .font(galmuriFont(12))
                .foregroundColor(active ? fp.primaryText : fp.border)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(active ? fp.primary : fp.cell)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
    }

    private func itemGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            content()
        }
    }

    private func shopSeedItem(_ seed: SeedKind) -> some View {
        Button(action: {
            purchaseQuantity = 1
            selectedSeedForPurchase = seed
        }) {
            VStack(spacing: 3) {
                cropImage(seed.growthImageName, fallbackColor: seedColor(seed), size: 24)
                Text(seed.displayName)
                    .font(galmuriFont(9)).foregroundColor(fp.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                Text(seed.displayedGrowthTime).font(galmuriFont(9)).foregroundColor(fp.inkDim)
                HStack(spacing: 2) {
                    Circle().fill(rt.yellow).frame(width: 11, height: 11)
                        .overlay(Circle().strokeBorder(fp.border, lineWidth: 2))
                    Text("\(seed.purchasePrice)").font(galmuriFont(10)).foregroundColor(fp.border)
                }
            }
            .padding(.horizontal, 5).padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(
            "\(seed.displayName) 구매 수량 선택",
            "Choose quantity of \(seed.displayName) to buy"
        ))
    }

    private func shopCatItem(_ cat: CodexCatEntry) -> some View {
        Button(action: { selectedCatForPurchase = cat }) {
            VStack(spacing: 2) {
                catProductImage(cat, size: 32)
                Text(cat.name)
                    .font(galmuriFont(9))
                    .foregroundColor(fp.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 2) {
                    Circle().fill(rt.yellow).frame(width: 10, height: 10)
                        .overlay(Circle().strokeBorder(fp.border, lineWidth: 2))
                    Text(L10n.number(cat.purchasePrice))
                        .font(galmuriFont(9))
                        .foregroundColor(fp.border)
                }
            }
            .padding(.horizontal, 4).padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(
            "\(cat.name), \(L10n.number(cat.purchasePrice))코인에 구매",
            "Buy \(cat.name) for \(L10n.number(cat.purchasePrice)) coins"
        ))
    }

    private func shopFurnitureItem(_ furniture: FurnitureItem) -> some View {
        Button(action: {
            purchaseQuantity = 1
            selectedFurnitureForPurchase = furniture
        }) {
            VStack(spacing: 2) {
                FurnitureAssetImage(furniture: furniture, size: 34)
                Text(furniture.displayName)
                    .font(galmuriFont(8))
                    .foregroundColor(fp.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                HStack(spacing: 2) {
                    Circle().fill(rt.yellow).frame(width: 10, height: 10)
                        .overlay(Circle().strokeBorder(fp.border, lineWidth: 2))
                    Text(L10n.number(furniture.purchasePrice))
                        .font(galmuriFont(8))
                        .foregroundColor(fp.border)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(
            "\(furniture.displayName) 구매 수량 선택",
            "Choose quantity of \(furniture.displayName) to buy"
        ))
    }

    @ViewBuilder private func catProductImage(_ cat: CodexCatEntry, size: CGFloat) -> some View {
        if let image = CatIdleCache.image(cat.idleResource) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            catIcon
        }
    }

    private func seedPurchasePopup(for seed: SeedKind) -> some View {
        let totalPrice = seed.purchasePrice * purchaseQuantity
        let canPurchase = state.coins >= totalPrice
        let maxAffordableQuantity = max(1, state.coins / seed.purchasePrice)
        return VStack(spacing: 14) {
            popupHeader(L10n.text("\(seed.displayName) 구매", "Buy \(seed.displayName)")) {
                selectedSeedForPurchase = nil
            }
            cropImage(seed.growthImageName, fallbackColor: seedColor(seed), size: 48)
            Text(L10n.text(
                "현재 보유 \(state.seedCount(seed))개",
                "Owned: \(state.seedCount(seed))"
            ))
                .font(galmuriFont(11))
                .foregroundColor(fp.inkDim)
            HStack(spacing: 12) {
                quantityButton(systemName: "minus", enabled: purchaseQuantity > 1) {
                    purchaseQuantity -= 1
                }
                Text(L10n.count(purchaseQuantity))
                    .font(galmuriFont(16))
                    .foregroundColor(fp.border)
                    .frame(minWidth: 58)
                quantityButton(systemName: "plus", enabled: purchaseQuantity < maxAffordableQuantity) {
                    purchaseQuantity += 1
                }
                quantityMaxButton(
                    enabled: state.coins >= seed.purchasePrice && purchaseQuantity < maxAffordableQuantity
                ) {
                    purchaseQuantity = maxAffordableQuantity
                }
            }
            popupActionButton(L10n.text(
                "\(totalPrice)코인에 구매",
                "Buy for \(totalPrice) coins"
            ), enabled: canPurchase) {
                if state.purchase(seed, quantity: purchaseQuantity) {
                    selectedSeedForPurchase = nil
                }
            }
        }
        .padding(16)
        .frame(width: 250)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(Rectangle().fill(Color.black.opacity(0.3)).offset(x: 5, y: 5))
    }

    private func catPurchasePopup(for cat: CodexCatEntry) -> some View {
        let alreadyOwned = state.isCatUnlocked(id: cat.id)
        return VStack(spacing: 14) {
            popupHeader(L10n.text("\(cat.name) 구매", "Buy \(cat.name)")) {
                selectedCatForPurchase = nil
            }
            catProductImage(cat, size: 64)
            Text(L10n.text(
                "가격 \(L10n.number(cat.purchasePrice))코인",
                "Price: \(L10n.number(cat.purchasePrice)) coins"
            ))
                .font(galmuriFont(11))
                .foregroundColor(fp.inkDim)
            popupActionButton(
                alreadyOwned
                    ? L10n.text("보유 중", "Owned")
                    : L10n.text(
                        "\(L10n.number(cat.purchasePrice))코인에 구매",
                        "Buy for \(L10n.number(cat.purchasePrice)) coins"
                    ),
                enabled: !alreadyOwned && state.coins >= cat.purchasePrice
            ) {
                if state.purchaseCat(id: cat.id, unitPrice: cat.purchasePrice) {
                    selectedCatForPurchase = nil
                }
            }
        }
        .padding(16)
        .frame(width: 250)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(Rectangle().fill(Color.black.opacity(0.3)).offset(x: 5, y: 5))
    }

    private func furniturePurchasePopup(for furniture: FurnitureItem) -> some View {
        let totalPrice = furniture.purchasePrice * purchaseQuantity
        let canPurchase = state.coins >= totalPrice
        let maxAffordableQuantity = max(1, state.coins / furniture.purchasePrice)
        return VStack(spacing: 14) {
            popupHeader(L10n.text(
                "\(furniture.displayName) 구매",
                "Buy \(furniture.displayName)"
            )) {
                selectedFurnitureForPurchase = nil
            }
            FurnitureAssetImage(furniture: furniture, size: 82)
            Text(L10n.text(
                "현재 보유 \(state.furnitureCount(furniture))개",
                "Owned: \(state.furnitureCount(furniture))"
            ))
                .font(galmuriFont(11))
                .foregroundColor(fp.inkDim)
            HStack(spacing: 12) {
                quantityButton(systemName: "minus", enabled: purchaseQuantity > 1) {
                    purchaseQuantity -= 1
                }
                Text(L10n.count(purchaseQuantity))
                    .font(galmuriFont(16))
                    .foregroundColor(fp.border)
                    .frame(minWidth: 58)
                quantityButton(
                    systemName: "plus",
                    enabled: purchaseQuantity < maxAffordableQuantity
                ) {
                    purchaseQuantity += 1
                }
                quantityMaxButton(
                    enabled: state.coins >= furniture.purchasePrice
                        && purchaseQuantity < maxAffordableQuantity
                ) {
                    purchaseQuantity = maxAffordableQuantity
                }
            }
            popupActionButton(L10n.text(
                "\(L10n.number(totalPrice))코인에 구매",
                "Buy for \(L10n.number(totalPrice)) coins"
            ), enabled: canPurchase) {
                if state.purchase(furniture, quantity: purchaseQuantity) {
                    selectedFurnitureForPurchase = nil
                }
            }
        }
        .padding(16)
        .frame(width: 250)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(Rectangle().fill(Color.black.opacity(0.3)).offset(x: 5, y: 5))
    }

    private func catUnlockPopup(notice: CatUnlockNotice, cat: CodexCatEntry) -> some View {
        let message = notice.source == .harvest
            ? L10n.text("수확 중 새로운 고양이를 만났어요!", "You met a new cat while harvesting!")
            : L10n.text("상점에서 새로운 고양이를 데려왔어요!", "You brought home a new cat from the shop!")
        return VStack(spacing: 13) {
            Text(L10n.text("새 고양이 획득!", "New Cat!"))
                .font(galmuriFont(17))
                .foregroundColor(fp.border)
            catProductImage(cat, size: 104)
            Text(cat.name)
                .font(galmuriFont(16))
                .foregroundColor(fp.border)
            Text(message)
                .font(galmuriFont(10))
                .foregroundColor(fp.inkDim)
                .multilineTextAlignment(.center)
            popupActionButton(L10n.text("확인", "OK"), enabled: true) {
                state.dismissCatUnlockNotice()
            }
        }
        .padding(18)
        .frame(width: 270)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(Rectangle().fill(Color.black.opacity(0.3)).offset(x: 5, y: 5))
    }

    private func codexCatPopup(for cat: CodexCatEntry) -> some View {
        let isUnlocked = state.isCatUnlocked(id: cat.id)
        let isSelected = state.selectedCat.id == cat.id
        let statusText: String = {
            if isUnlocked { return L10n.text("보유 중인 고양이", "Owned cat") }
            if cat.id == "oddeye" {
                return L10n.text("당근 수확 시 0.0001% 확률로 획득", "0.0001% chance from harvesting carrots")
            }
            if cat.id == "cheese" {
                return L10n.text("당근 수확 시 0.1% 확률로 획득", "0.1% chance from harvesting carrots")
            }
            if cat.id == "gray" {
                return L10n.text("양배추 수확 시 0.1% 확률로 획득", "0.1% chance from harvesting cabbages")
            }
            if cat.id == "calico" {
                return L10n.text("양배추 수확 시 0.0001% 확률로 획득", "0.0001% chance from harvesting cabbages")
            }
            return L10n.text("상점에서 구매할 수 있어요", "Available from the shop")
        }()
        let buttonTitle = isSelected
            ? L10n.text("현재 사용 중", "Currently selected")
            : (isUnlocked
                ? L10n.text("이 고양이로 변경하기", "Select this cat")
                : L10n.text("아직 획득하지 못했어요", "Not yet unlocked"))

        return VStack(spacing: 14) {
            popupHeader(cat.name) { selectedCodexCat = nil }
            catProductImage(cat, size: 104)
            Text(statusText)
                .font(galmuriFont(11))
                .foregroundColor(fp.inkDim)
            popupActionButton(buttonTitle, enabled: isUnlocked && !isSelected) {
                if state.selectCat(id: cat.id) {
                    selectedCodexCat = nil
                }
            }
        }
        .padding(16)
        .frame(width: 270)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(Rectangle().fill(Color.black.opacity(0.3)).offset(x: 5, y: 5))
    }

    private func popupHeader(_ title: String, onClose: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(galmuriFont(15))
                .foregroundColor(fp.border)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(fp.border)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
    }

    private func popupActionButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(galmuriFont(13))
                .foregroundColor(enabled ? fp.primaryText : fp.inkDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(enabled ? fp.primary : fp.cell)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func storedSeedItem(_ seed: SeedKind) -> some View {
        VStack(spacing: 4) {
            cropImage(seed.growthImageName, fallbackColor: seedColor(seed), size: 28)
            Text(seed.displayName)
                .font(galmuriFont(9)).foregroundColor(fp.border)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
            Text(L10n.count(state.seedCount(seed)))
                .font(galmuriFont(10)).foregroundColor(fp.inkDim)
        }
        .padding(.horizontal, 5).padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
        .background(fp.cell)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
    }

    private func storedCropItem(_ crop: CropKind) -> some View {
        Button(action: { openSalePopup(for: crop) }) {
            VStack(spacing: 4) {
                cropImage(crop.imageName, fallbackColor: crop == .carrot ? fp.carrot : fp.cabbage, size: 28)
                Text(crop.displayName)
                    .font(galmuriFont(9)).foregroundColor(fp.border)
                Text(L10n.text(
                    "\(state.cropCount(crop))개 · \(crop.salePrice)코인",
                    "\(state.cropCount(crop)) · \(crop.salePrice) coins"
                ))
                    .font(galmuriFont(9)).foregroundColor(fp.inkDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4).padding(.vertical, 5)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(
            "\(crop.displayName) 판매 수량 선택",
            "Choose quantity of \(crop.displayName) to sell"
        ))
    }

    private func storedFurnitureItem(_ furniture: FurnitureItem) -> some View {
        Button(action: { selectFurnitureForPlacement(furniture) }) {
            VStack(spacing: 4) {
                FurnitureAssetImage(furniture: furniture, size: 30)
                Text(furniture.displayName)
                    .font(galmuriFont(8))
                    .foregroundColor(fp.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)
                Text(L10n.text(
                    "\(state.furnitureCount(furniture))개 · 집에 놓기",
                    "\(state.furnitureCount(furniture)) · Place"
                ))
                    .font(galmuriFont(8))
                    .foregroundColor(fp.inkDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(
            "\(furniture.displayName) 집에 배치",
            "Place \(furniture.displayName) in the home"
        ))
    }

    private func selectFurnitureForPlacement(_ furniture: FurnitureItem) {
        guard state.furnitureCount(furniture) > 0 else { return }
        selectedPlacedFurnitureForReposition = nil
        selectedFurnitureForPlacement = furniture
        isHomePlacementModeEnabled = true
        clearHomePlacementPointer()
        state.selectedMapLocation = .home
    }

    private func openSalePopup(for crop: CropKind) {
        saleQuantity = 1
        selectedCropForSale = crop
    }

    private func salePopup(for crop: CropKind) -> some View {
        let ownedCount = state.cropCount(crop)
        let totalPrice = crop.salePrice * saleQuantity
        return VStack(spacing: 14) {
            HStack {
                Text(L10n.text("\(crop.displayName) 판매", "Sell \(crop.displayName)"))
                    .font(galmuriFont(15))
                    .foregroundColor(fp.border)
                Spacer(minLength: 0)
                Button(action: { selectedCropForSale = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(fp.border)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            cropImage(crop.imageName, fallbackColor: crop == .carrot ? fp.carrot : fp.cabbage, size: 48)

            Text(L10n.text("보유 수량 \(ownedCount)개", "Owned: \(ownedCount)"))
                .font(galmuriFont(11))
                .foregroundColor(fp.inkDim)

            HStack(spacing: 12) {
                quantityButton(systemName: "minus", enabled: saleQuantity > 1) {
                    saleQuantity -= 1
                }
                Text(L10n.count(saleQuantity))
                    .font(galmuriFont(16))
                    .foregroundColor(fp.border)
                    .frame(minWidth: 58)
                quantityButton(systemName: "plus", enabled: saleQuantity < ownedCount) {
                    saleQuantity += 1
                }
                quantityMaxButton(enabled: saleQuantity < ownedCount) {
                    saleQuantity = ownedCount
                }
            }

            Button(action: {
                if state.sell(crop, quantity: saleQuantity) {
                    selectedCropForSale = nil
                }
            }) {
                Text(L10n.text("\(totalPrice)코인에 판매", "Sell for \(totalPrice) coins"))
                    .font(galmuriFont(13))
                    .foregroundColor(fp.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(fp.primary)
                    .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
            }
            .buttonStyle(.plain)
            .disabled(ownedCount == 0)
        }
        .padding(16)
        .frame(width: 250)
        .background(fp.panel)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .offset(x: 5, y: 5)
        )
    }

    private func quantityButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(enabled ? fp.border : fp.inkDim)
                .frame(width: 34, height: 30)
                .background(fp.cell)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func quantityMaxButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("MAX")
                .font(galmuriFont(9))
                .foregroundColor(enabled ? fp.border : fp.inkDim)
                .frame(width: 42, height: 30)
                .background(fp.cell)
                .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func seedColor(_ seed: SeedKind) -> Color {
        switch seed {
        case .carrot: return fp.carrot
        case .cabbage: return fp.cabbage
        }
    }

    private func cropEntry(_ crop: CropKind) -> some View {
        VStack(spacing: 4) {
            cropImage(crop.imageName, fallbackColor: crop == .carrot ? fp.carrot : fp.cabbage)
            Text(crop.displayName)
                .font(galmuriFont(10))
                .foregroundColor(fp.border)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 5).padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
        .background(fp.cell)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
    }

    @ViewBuilder private func cropImage(_ resource: String, fallbackColor: Color, size: CGFloat = 40) -> some View {
        if let image = GuiAssetCache.image(resource) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            sproutIcon(fallbackColor)
        }
    }

    private func catEntry(_ cat: CodexCatEntry) -> some View {
        Button(action: { selectedCodexCat = cat }) {
            VStack(spacing: 4) {
                catIdleImage(cat.idleResource)
                Text(cat.name)
                    .font(galmuriFont(10))
                    .foregroundColor(fp.border)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 5).padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(
            "\(cat.name) 고양이 상세 보기",
            "View details for \(cat.name)"
        ))
    }

    @ViewBuilder private func catIdleImage(_ resource: String) -> some View {
        if let image = CatIdleCache.image(resource) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else {
            catIcon
        }
    }

    private func sproutIcon(_ color: Color) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 6, height: 8)
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 6, height: 10)
        }
        .frame(height: 16)
    }

    private var catIcon: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 10) {
                Triangle().fill(fp.inkDim).frame(width: 8, height: 8)
                Triangle().fill(fp.inkDim).frame(width: 8, height: 8)
            }
            Circle().fill(fp.inkDim).frame(width: 20, height: 20).padding(.top, 4)
        }
        .frame(height: 24)
    }

    private var emptySlot: some View {
        ZStack {
            fp.cell
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(fp.inkDim)
        }
        .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
    }

    // MARK: 하단 탭 - 상점/창고/도감/기록 전환

    private var tabBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(fp.border).frame(height: 3)
            HStack(spacing: 0) {
                ForEach(FarmTab.allCases) { tab in
                    let active = state.selectedFarmTab == tab
                    Button(action: { state.selectedFarmTab = tab }) {
                        Text(tab.displayName)
                            .font(galmuriFont(14))
                            .foregroundColor(active ? fp.primaryText : fp.border)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(active ? fp.primary : fp.cell)
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(fp.border).frame(width: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
