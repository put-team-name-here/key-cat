# keycat 축소화면(collapsed view) 레트로 픽셀 구현 - 세션 핸드오프

## 프로젝트 위치 / 브랜치
- 경로: `/Users/ujeonghyeon/Desktop/dev/myDev/typing-farm` (레포명 typing-farm, 패키지명 keycat, 타깃 KeyCat, 소스 `Sources/KeyCat/`)
- 브랜치: `feat/collapsed-view` (develop 에서 분기, **아직 커밋 안 함 - 워킹트리 상태**). 완료 후 develop 으로 PR 예정.
- 커밋 규칙: Conventional Commits(`type(scope): 요약`, type/scope 영어 소문자, 요약·본문 한글), 한 프롬프트=한 의미 단위 커밋, em dash("-"로) 금지, Co-Authored-By 등 서명 트레일러 금지, 새 작업은 새 브랜치.
- 커밋 훅 주의: 커밋 요약이 Conventional Commits 형식이 아니면 훅이 거부한다(merge 도 `type:` 접두사 필요, 예: `feat(assets): ...`).

## 무엇을 만드는가
타이핑으로 농사짓는 맥 메뉴바 상주 오버레이 위젯 keycat. 전역 keyDown 을 CGEventTap 으로 세는 게임. 이번 작업은 claude.ai/design 시안 `축소화면.dc.html`(352px 폭 가로형 레트로 픽셀 카드) 대로 `OverlayView.collapsedView` 를 실제 구현하는 것.

## 이번 세션에서 확정한 결정 (중요, ooo interview 세션 interview_20260710_024809 결과)
- **베이스 브랜치**: develop 에서 `feat/collapsed-view` 분기(구 브랜치 feat/retro-pixel-theme, feat/cat-walk-animation 은 개명 전 경로 `Sources/TypingFarm/` 기준이라 그 위에서 분기하면 keycat 개명·NSMenu 작업을 잃음. 그래서 로직만 이식).
- **고양이 스프라이트**: CatSprite 배회 로직을 이식하되 이미지는 **신규 `assets/cats/` 6종**(cheese/gray/siamese/sphynx/tuxedo/oddeye) 사용. 배회 애니메이션 **9fps**(feat/cat-walk-animation 의 fps 비교로 사용자가 정한 값). 앞선 "구 브랜치 walk_down/side png 이식" 결정을 대체함.
- **테마 격리**: 레트로 픽셀 팔레트/Galmuri11 폰트는 **collapsedView 전용**. expandedView 는 기존 `Theme.rhodes`(RHODES 콘솔) 유지. 확장화면 마이그레이션은 후속 브랜치.
- **"변경" 버튼**: 고양이 6종 순환 전환 + **UserDefaults 영속**(재실행 시 마지막 선택 유지).
- **"설정" 버튼**: 기존 메뉴바 `statusItem.menu`(NSMenu: 농장 표시/숨김, 기록 일시정지, 종료)를 버튼 위치에 **popUp 으로 실연결**(신규 설정 화면 없음).
- **확장 아이콘 버튼**: 기존 `AppDelegate.toggleSize()` 실연결 유지(이미 작동).
- **수확 상태 타일**: 표시 전용, `state.harvestAvailable` 바인딩(수확 시스템 미구현 자리표시).
- **위젯 크기**: 시안대로 **352pt 폭 가로형 고정**(높이는 콘텐츠 기준 자연 결정). 확장(405x838)과의 우상단 고정 전환 애니메이션 자연스러움 확인 포함.
- **완료 기준**: `swift build` 통과 + **수동 실행 검증**(버튼 4개 동작 / 배회 9fps / 캐릭터 선택 재실행 영속). 유닛 테스트는 범위 외.
- **범위 외**: expandedView 테마 변경, CatCompareView(fps 비교 개발창) 이식, 픽셀 단위 대조, 코인/수확 시스템 구현.

## 이미 구현됨 (워킹트리, 커밋 안 됨, `swift build` 통과)
- `Sources/KeyCat/CatSprite.swift` (신규) - 핵심 모듈. 재사용할 것.
  - `CatCharacter`/`CatCatalog.all`: 고양이 6종 메타(id/name/front/leftSheet/rightSheet). id 는 UserDefaults 저장용 안정 키.
  - oddeye 는 좌우 눈색이 달라 반전 불가 -> `rightSheet` 별도 지정(다른 고양이는 nil, leftSheet 좌우반전).
  - `SpriteSheet`: 384x384 PNG 를 3x3 격자 8프레임으로 크롭. `Bundle.module.url(..., subdirectory: "cats")` 로 로드.
  - `SpriteCache`: 리소스명 기준 시트 캐시(캐릭터 전환해도 재사용).
  - `CatMotion`: 60fps 타이머 배회 두뇌(타이핑 무관 랜덤 배회, 멈춤 0.4~1.8s). `WalkingCat(character:spriteSize:46 fps:9 speed:26)`.
  - 경고: 204행 `onChange(of:perform:)` macOS 14 deprecation(치명 아님, 2-param 클로저로 교체 가능).
- `Sources/KeyCat/Theme.swift` (수정) - `RetroTheme.shared`(레트로 팔레트: cardBg #b4ccc2, ink #3b2b22, panel #efe7d0, yellow #e8bf52, harvestReady #7fbf5c, harvestWait #c2beb2, pink/pinkKey 등) + `galmuriFont(_:)`(=`.custom("Galmuri11-Regular", size:)`) 추가. 기존 `Theme.rhodes`/`CutCorner`/`LBracket` 는 그대로.
- `Package.swift` (수정) - KeyCat 타깃에 `resources: [.copy("Resources/cats"), .copy("Resources/fonts")]` 추가.
- `Sources/KeyCat/Resources/cats/` (신규) - 정규화된 13개 png: 5종 `<id>_front.png`/`<id>_side.png` + oddeye `oddeye_front/left/right.png`. (원본 assets/cats/ 는 이름 불일치가 있어 여기로 정규화 복사함: 예 oddeye 는 white_odd_cat_front_walk, left_walk/right_walk 였음.)
- `Sources/KeyCat/Resources/fonts/` (신규) - `Galmuri11.ttf` + `OFL.txt`(라이선스).

## 아직 안 됨 (다음에 할 일, 순서대로)
1. **`Sources/KeyCat/AppState.swift`** - 선택 캐릭터 영속 추가.
   - `@Published var selectedCatIndex`(또는 id) + UserDefaults 로드/저장, `cycleCat()` 메서드. `CatCatalog.all` 인덱스 기준. 앱 시작 시 저장값으로 초기화.
2. **`Sources/KeyCat/OverlayView.swift` `collapsedView`** - 옛 RHODES 플레이스홀더(31행 "고양이\n캐릭터" Text)를 시안대로 전면 교체.
   - 시안 구조: 좌측 118x118 고양이 박스(대각 줄무늬 배경 stripeA/B + 테두리 ink 3px, 안에 `WalkingCat(character: 선택캣, fps:9)`) + 우하단 원형 44px yellow "변경" 버튼.
   - 우측 열: [확장 아이콘 버튼(toggleSize) + "설정" 버튼] 행 -> 키보드 아이콘+"{counter.count}자" 타일 -> 코인 아이콘+"{coins}" 타일 -> 수확 상태 타일(harvestAvailable: 초록 "수확할 수 있어요!" / 회색 "아직 자라는 중").
   - 팔레트는 `RetroTheme.shared`, 폰트는 `galmuriFont(_:)`. 카드 = cardBg 배경 + ink 3px 테두리 + 그림자 5px5px.
   - "변경" 버튼 액션 = `state.cycleCat()`, "설정" 버튼 액션 = 신규 콜백(아래 3), 확장 = 기존 `onToggleSize`.
   - collapsedView 는 현재 62pt placeholderBox 붕괴 이슈 있으니 고양이 박스 118 높이로 키우면 배회 정상(WalkingCat spriteSize 46 -> margin 25, 118 박스면 배회 범위 확보).
3. **`Sources/KeyCat/AppDelegate.swift`** - 3가지.
   - (a) `collapsedSize` 를 352 폭 가로형으로 변경(예: `NSSize(width: 352, height: ~230)`, 시안 비율 확인). 우측 상단 배치 origin 계산도 이 값 사용하니 자동 반영됨. toggleSize 전환 애니메이션(352->405x838) 육안 확인.
   - (b) **Galmuri11 폰트 런타임 등록**(핵심 함정): `applicationDidFinishLaunching` 에서 `Bundle.module.url(forResource:"Galmuri11", withExtension:"ttf", subdirectory:"fonts")` -> `CTFontManagerRegisterFontsForURL`. 미등록 시 `galmuriFont` 가 시스템 폰트로 대체돼 레트로 느낌이 사라짐. PostScript 이름이 정확히 `Galmuri11-Regular` 인지 등록 후 확인 필요(미확인 - 폰트 내부 이름 다르면 `.custom` 이 실패해 조용히 폴백).
   - (c) "설정" 버튼용 콜백: `OverlayView` 에 `onOpenSettings: () -> Void` 추가하고, AppDelegate 에서 `statusItem.menu` 를 버튼 근처에서 `popUp(positioning:at:in:)` 하도록 배선(popUp 하려면 잠시 `statusItem.menu = nil` 후 표시하거나 `NSMenu.popUp` 직접 호출 - NSStatusItem.menu 로 붙은 메뉴는 popUp 제약 있으니 검증 필요).
4. **수동 검증** - `swift run` 으로 실행: 캐릭터 순환/설정 popUp/확장 전환/배회 9fps/재실행 후 캐릭터 유지 확인.
5. **커밋 & PR** - 의미 단위 커밋(예: `feat(overlay): 축소화면 레트로 픽셀 구현`) 후 develop 으로 PR.

## 재사용할 코어 / 건드리지 말 것
- `Sources/KeyCat/CatSprite.swift` - 배회/스프라이트 로직 완성됨. WalkingCat 만 collapsedView 에서 호출하면 됨.
- `Sources/KeyCat/Theme.swift` 의 `Theme.rhodes`, `CutCorner`, `LBracket`, `Color(hex:)` - expandedView 가 씀. 보존.
- `Sources/KeyCat/KeyCounter.swift` - CGEventTap 카운터. `counter.count`(실데이터), `permissionGranted`, `togglePause`.
- `AppDelegate` 의 `statusItem.menu`(NSMenu) - "설정" popUp 재사용 대상.

## 현재 상태
- 빌드: `swift build` **통과**(경고 1건: CatSprite.swift 204행 onChange deprecation).
- 실행 검증: **미검증**(폰트 등록, 배회 렌더, 캐릭터 전환, 설정 popUp 모두 실행 확인 안 함).
- develop 에 이번 세션에 머지 완료: `feat/add-assets`(고양이 6종 스프라이트 assets/, 커밋 5841df9, 푸시됨). `--allow-unrelated-histories`(GitHub main 계보) + README 충돌은 develop 쪽 유지로 해소.
- 워킹트리(feat/collapsed-view): M Package.swift, M Theme.swift, ?? CatSprite.swift, ?? Resources/. (.idea/, scratchpad/, handoff/ 는 무시.)

## 제약 / 함정
- **Galmuri11 PostScript 이름 미확인**: `galmuriFont` 는 `Galmuri11-Regular` 를 참조. 폰트 내부 이름이 다르면 조용히 시스템 폰트로 폴백하니 등록 후 실제 이름 확인 필수.
- **NSStatusItem.menu 의 popUp 제약**: statusItem 에 붙인 NSMenu 를 임의 위치에 popUp 하려면 배선 검증 필요(그냥 popUp 호출이 막힐 수 있음).
- **원본 assets/cats/ 이름 불일치**: oddeye 는 `white_odd_cat_front_walk`, `left_walk`/`right_walk` 로 다른 고양이(`_front_walk`,`_side_walk`)와 명명이 다름. 이미 Resources/cats/ 로 정규화 복사했으니 신규 코드는 Resources 쪽만 참조.
- **62pt 박스 배회 붕괴**: WalkingCat margin=sprite/2+2. 고양이 박스를 시안대로 118 높이로 두면 정상.
- `swift run` 실행 시 입력 모니터링 권한이 실행 바이너리/터미널에 귀속(README 참고).
- 코인 타일 표시값 출처 미결(coins=0 자리표시). 시안대로 "000" 또는 state.coins 표시.
