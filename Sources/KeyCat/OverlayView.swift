import SwiftUI
import AppKit

/// GUI PNG asset cache for small overlay status icons.
enum GuiAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let img = cache[name] { return img }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "gui"),
              let img = NSImage(contentsOf: url) else { return nil }
        cache[name] = img
        return img
    }
}

/// 도감에 표시할 idle 스프라이트 시트의 첫 프레임 캐시.
enum CatIdleCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let image = cache[name] { return image }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "cats"),
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
    let name: String
    let idleResource: String
}

private let codexCats: [CodexCatEntry] = [
    .init(id: "siamese", name: "샴", idleResource: "siamese_idle"),
    .init(id: "sphynx", name: "스핑크스", idleResource: "sphynx_idle"),
    .init(id: "cheese", name: "치즈", idleResource: "cheese_idle"),
    .init(id: "tuxedo", name: "턱시도", idleResource: "tuxedo_idle"),
    .init(id: "oddeye", name: "오드아이", idleResource: "oddeye_idle"),
    .init(id: "gray", name: "그레이", idleResource: "gray_idle"),
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
/// 축소(작은 위젯) / 확장(농장 콘솔) 두 화면을 state.expanded 로 전환.
struct OverlayView: View {
    @ObservedObject var counter: KeyCounter
    @ObservedObject var state: AppState
    var onToggleSize: () -> Void
    /// "설정" 버튼: 메뉴바 NSMenu 를 popUp (AppDelegate 배선)
    var onOpenSettings: () -> Void = {}

    private let rt = RetroTheme.shared
    private let fp = FarmPixelTheme.shared
    @State private var seedPickerTile: FarmTileCoordinate?
    @State private var selectedCropForSale: CropKind?
    @State private var saleQuantity = 1

    var body: some View {
        Group {
            if state.expanded {
                expandedView
            } else {
                collapsedView
            }
        }
    }

    // MARK: - 축소 화면 (레트로 픽셀 카드, 시안 축소화면.dc.html)

    /// 카드 하드 그림자(5px5px). 투명 패널 안에서 그림자용 여백을 확보한다.
    private var collapsedView: some View {
        HStack(alignment: .top, spacing: 14) {
            catColumn
            statsColumn
        }
        .padding(14)
        .frame(width: 352, alignment: .topLeading)
        .background(rt.cardBg)
        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.28))
                .offset(x: 5, y: 5)
        )
        .padding(.trailing, 5)
        .padding(.bottom, 5)
        .fixedSize()
    }

    // MARK: 좌측 - 고양이 박스 + "변경" 버튼

    private var catColumn: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                GrassBackground()
                WalkingCat(character: state.selectedCat, spriteSize: 46, fps: 9)
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
            .accessibilityLabel("고양이 변경")
            .offset(x: 10, y: 10)
        }
        .frame(width: 118, height: 118, alignment: .topLeading)
    }

    // MARK: 우측 - 상단 버튼행 + 정보 타일 3종

    private var statsColumn: some View {
        VStack(spacing: 7) {
            // 확대 + 설정 버튼
            HStack(spacing: 6) {
                Spacer(minLength: 0)
                Button(action: onToggleSize) {
                    guiControlIcon("zoom_in", size: 17)
                        .frame(width: 29, height: 27)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)

                Button(action: onOpenSettings) {
                    guiControlIcon("setting", size: 17)
                        .frame(width: 29, height: 27)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: false, vertical: true)

            // 기록한 글자 수
            infoTile {
                keyboardGlyph
                Spacer(minLength: 0)
                Text("\(counter.count)자")
                    .font(galmuriFont(14)).foregroundColor(rt.text)
            }

            // 보유 코인
            infoTile {
                coinGlyph
                Spacer(minLength: 0)
                Text("\(state.coins)")
                    .font(galmuriFont(14)).foregroundColor(rt.text)
            }

            // 수확 상태
            infoTile {
                Rectangle()
                    .fill(state.harvestAvailable ? rt.harvestReady : rt.harvestWait)
                    .frame(width: 11, height: 11)
                    .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 2))
                Text(state.harvestAvailable ? "수확할 수 있어요!" : "아직 자라는 중")
                    .font(galmuriFont(13)).foregroundColor(rt.text)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 정보 타일: panel 배경 + ink 3px 테두리 + 좌측 아이콘 행
    private func infoTile<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8, content: content)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(rt.panel)
            .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
    }

    /// assets/gui/key_cap_2.png 기반 타자 수 아이콘. 리소스 누락 시 기존 픽셀 아이콘으로 폴백.
    @ViewBuilder private var keyboardGlyph: some View {
        if let img = GuiAssetCache.image("key_cap_2") {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityLabel("타자 수")
        } else {
            legacyKeyboardGlyph
        }
    }

    /// assets/gui/coin_2.png 기반 보유 코인 아이콘. 리소스 누락 시 기존 픽셀 아이콘으로 폴백.
    @ViewBuilder private var coinGlyph: some View {
        if let img = GuiAssetCache.image("coin_2") {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityLabel("보유 코인")
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
    // 정적 구성: 씨앗/탭 콘텐츠는 자리표시일 뿐 실제 상점·창고 기능은 아직 없음.

    private var expandedView: some View {
        VStack(spacing: 0) {
            farmField
            resourceBar
            inventorySection
            tabBar
        }
        .frame(width: 360)
        .background(fp.panel)
        .overlay {
            if let crop = selectedCropForSale {
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCropForSale = nil }
                    salePopup(for: crop)
                }
            }
        }
        .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .offset(x: 6, y: 6)
        )
        .padding(.trailing, 6)
        .padding(.bottom, 6)
        .fixedSize()
    }

    // MARK: 밭 필드 - 잔디 배경 + 우상단 축소/설정 버튼

    private var farmField: some View {
        ZStack(alignment: .topLeading) {
            FarmFieldGrassView(field: state.farmField) { row, column in
                seedPickerTile = FarmTileCoordinate(row: row, column: column)
            }
            WalkingCat(
                character: state.selectedCat,
                spriteSize: 64,
                fps: 9,
                speed: 34,
                farmTask: state.farmWorkQueue.first,
                onFarmTaskComplete: state.completeFarmWork
            )
                .allowsHitTesting(false)
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
                Text("심을 씨앗")
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
                Text("창고에 보유한 씨앗이 없어요")
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
                            Text("\(state.seedCount(seed))개")
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
                Text("\(counter.count)자")
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
            categoryPill("씨앗")
            itemGrid {
                shopSeedItem(.carrot)
                shopSeedItem(.cabbage)
                ForEach(0..<6, id: \.self) { _ in emptySlot }
            }
        }
    }

    private var storageContent: some View {
        let ownedCrops = CropKind.allCases.filter { state.cropCount($0) > 0 }
        let occupiedCount = SeedKind.allCases.count + ownedCrops.count
        return itemGrid {
            ForEach(SeedKind.allCases) { seed in
                storedSeedItem(seed)
            }
            ForEach(ownedCrops) { crop in
                storedCropItem(crop)
            }
            ForEach(0..<max(0, 8 - occupiedCount), id: \.self) { _ in emptySlot }
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
        itemGrid {
            VStack(spacing: 6) {
                Text("기록 준비 중")
                    .font(galmuriFont(10))
                    .foregroundColor(fp.border)
                    .multilineTextAlignment(.center)
                Text("SOON")
                    .font(galmuriFont(9))
                    .foregroundColor(fp.inkDim)
            }
            .padding(.horizontal, 5).padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
            ForEach(0..<7, id: \.self) { _ in emptySlot }
        }
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
            Text(category.rawValue)
                .font(galmuriFont(14))
                .foregroundColor(active ? fp.primaryText : fp.border)
                .padding(.horizontal, 12).padding(.vertical, 5)
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
        Button(action: { state.purchase(seed) }) {
            VStack(spacing: 3) {
                cropImage(seed.growthImageName, fallbackColor: seedColor(seed), size: 24)
                Text(seed.displayName)
                    .font(galmuriFont(9)).foregroundColor(fp.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                Text("0m").font(galmuriFont(9)).foregroundColor(fp.inkDim)
                HStack(spacing: 2) {
                    Circle().fill(rt.yellow).frame(width: 11, height: 11)
                        .overlay(Circle().strokeBorder(fp.border, lineWidth: 2))
                    Text("00").font(galmuriFont(10)).foregroundColor(fp.border)
                }
            }
            .padding(.horizontal, 5).padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
            .background(fp.cell)
            .overlay(Rectangle().strokeBorder(fp.border, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(seed.displayName) 1개 구매")
    }

    private func storedSeedItem(_ seed: SeedKind) -> some View {
        VStack(spacing: 4) {
            cropImage(seed.growthImageName, fallbackColor: seedColor(seed), size: 28)
            Text(seed.displayName)
                .font(galmuriFont(9)).foregroundColor(fp.border)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
            Text("\(state.seedCount(seed))개")
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
                Text("\(state.cropCount(crop))개 · \(crop.salePrice)코인")
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
        .accessibilityLabel("\(crop.displayName) 판매 수량 선택")
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
                Text("\(crop.displayName) 판매")
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

            Text("보유 수량 \(ownedCount)개")
                .font(galmuriFont(11))
                .foregroundColor(fp.inkDim)

            HStack(spacing: 12) {
                quantityButton(systemName: "minus", enabled: saleQuantity > 1) {
                    saleQuantity -= 1
                }
                Text("\(saleQuantity)개")
                    .font(galmuriFont(16))
                    .foregroundColor(fp.border)
                    .frame(minWidth: 58)
                quantityButton(systemName: "plus", enabled: saleQuantity < ownedCount) {
                    saleQuantity += 1
                }
            }

            Button(action: {
                if state.sell(crop, quantity: saleQuantity) {
                    selectedCropForSale = nil
                }
            }) {
                Text("\(totalPrice)코인에 판매")
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
                        Text(tab.rawValue)
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
