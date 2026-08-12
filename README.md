# KeyCat
타이핑으로 농사짓는 맥 오버레이 위젯 **keycat**의 기술 검증(PoC). 오버레이 상시 표시와 전역 타자 카운트라는 두 핵심 리스크 검증에서 출발해, 지금은 씨앗 구매 → 파종 → 급수 → 성장 → 수확 → 판매로 이어지는 농장 루프와 고양이 수집 요소까지 갖춘 상태다.
macOS 14 이상을 지원합니다.

## Xcode 실행

1. `KeyCat.xcodeproj`를 Xcode로 엽니다.
2. `KeyCat` Scheme과 `My Mac`을 선택합니다.
3. Signing & Capabilities에서 본인의 Team을 선택합니다.
4. Run (`⌘R`)을 실행합니다.
5. 시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링에서 KeyCat을 허용합니다.

권한은 번들 ID와 서명에 연결됩니다. 배포 중 번들 ID나 서명을 바꾸면 사용자가 권한을 다시 허용해야 할 수 있습니다.

## 배포

이 앱은 전역 키 입력을 감지하므로 Mac App Store 샌드박스 배포 대상이 아닙니다. Developer ID로 직접 배포하고 Apple 공증을 거치는 방식을 사용합니다.

1. [Config/Release.xcconfig](Config/Release.xcconfig)의 `PRODUCT_BUNDLE_IDENTIFIER`를 본인 소유 식별자로 변경합니다.
2. Xcode의 KeyCat 타깃에서 Team과 `Developer ID Application` 인증서를 설정합니다.
3. 메뉴에서 Product > Archive를 실행합니다.
4. Organizer에서 Distribute App > Developer ID > Upload를 선택해 공증합니다.
5. 공증 완료 후 Export한 앱을 DMG 또는 ZIP으로 배포합니다.

버전은 `MARKETING_VERSION`, 빌드 번호는 `CURRENT_PROJECT_VERSION`에서 관리합니다.

## 구조

```text
keyboard-game/
├── KeyCat.xcodeproj/          # Xcode 앱 프로젝트와 공유 Scheme
├── Config/                    # 번들 ID, 버전, 서명, entitlement 설정
├── Sources/KeyCat/            # 앱 Swift 소스
│   └── Resources/             # 실제 앱 번들에 포함되는 런타임 리소스
├── Artwork/SourceAssets/      # 앱에 포함되지 않는 원본/후보 그래픽
├── Documentation/Handoff/     # 과거 작업 인수인계 기록
├── Package.swift              # CLI 개발용 Swift Package 호환 설정
└── README.md
```

리소스를 앱에서 사용하려면 `Sources/KeyCat/Resources`의 알맞은 하위 폴더에 넣고 Xcode 프로젝트의 Resources 빌드 단계에 포함된 폴더인지 확인합니다. `Artwork/SourceAssets` 파일은 자동으로 앱에 포함되지 않습니다.

## CLI 개발

1. [Config/Release.xcconfig](Config/Release.xcconfig)의 `PRODUCT_BUNDLE_IDENTIFIER`를 본인 소유 식별자로 변경합니다.
2. Xcode의 KeyCat 타깃에서 Team과 `Developer ID Application` 인증서를 설정합니다.
3. 메뉴에서 Product > Archive를 실행합니다.
4. Organizer에서 Distribute App > Developer ID > Upload를 선택해 공증합니다.
5. 공증 완료 후 Export한 앱을 DMG 또는 ZIP으로 배포합니다.

버전은 `MARKETING_VERSION`, 빌드 번호는 `CURRENT_PROJECT_VERSION`에서 관리합니다.

## 구조

```text
keyboard-game/
├── KeyCat.xcodeproj/          # Xcode 앱 프로젝트와 공유 Scheme
├── Config/                    # 번들 ID, 버전, 서명, entitlement 설정
├── Sources/KeyCat/            # 앱 Swift 소스
│   └── Resources/             # 실제 앱 번들에 포함되는 런타임 리소스
├── Artwork/SourceAssets/      # 앱에 포함되지 않는 원본/후보 그래픽
├── Documentation/Handoff/     # 과거 작업 인수인계 기록
├── Package.swift              # CLI 개발용 Swift Package 호환 설정
└── README.md
```

리소스를 앱에서 사용하려면 `Sources/KeyCat/Resources`의 알맞은 하위 폴더에 넣고 Xcode 프로젝트의 Resources 빌드 단계에 포함된 폴더인지 확인합니다. `Artwork/SourceAssets` 파일은 자동으로 앱에 포함되지 않습니다.


## CLI 개발
- **농장 표시/숨김** ⌘F - 오버레이 창 토글
- 정보 항목(badge로 값 표시, 메뉴 열 때마다 갱신)
  - 기록한 글자 / 보유 코인 / 수확 가능 여부
- **설정** 섹션
  - 기록 일시 정지 ⌘P - CGEventTap을 꺼서 기록 중단, 다시 누르면 재개
  - 오토 모드 ⌘A - 파종/급수/수확을 자동으로 반복 진행
  - 프로그램 종료 ⌘Q

Swift Package 경로도 유지되어 있습니다.

```sh
swift run
```

배포 및 권한 검증은 반드시 Xcode에서 생성한 `.app`으로 수행합니다.

밭 잔디는 짙은 잔디/꽃 잔디를 **랜덤 배치**하고, 그 배치와 칸별 상태를
`~/Library/Application Support/KeyCat/farm.json`(8열×12행)에 저장해 재실행 후에도 복원한다.

**코인**: 타이핑 10회당 1코인이 자동 지급되고, 수확한 작물을 창고에서 판매하면 판매가만큼 추가로 쌓인다.

**밭 상태 흐름**: 빈 칸(마른 땅) 탭 → 씨앗 선택 후 파종 → 고양이가 이동해 급수 → 일정 시간 성장 → 수확 가능 상태가 되면 고양이가 수확해 창고에 적립. 수확 시 확률적으로 새 고양이가 드랍된다(당근: 치즈 0.1% · 오드아이 0.0001%, 양배추: 그레이 0.1% · 삼색냥 0.0001%, 이미 보유한 고양이는 대상에서 제외).

**오토 모드**(⌘A 또는 확장 화면 버튼): 켜두면 빈 밭에 보유 씨앗을 자동으로 순서대로 파종하고, 급수·수확도 고양이가 알아서 처리한다. 심을 씨앗이 떨어지면 고양이가 밭 한쪽의 고양이 집으로 이동해 "씨앗 부족" 표시를 띄운다. 오버레이 창을 숨기거나 축소해도 진행 중이던 작업은 백그라운드에서 계속 완료된다.

하단 탭(상점/창고/도감/기록)은 모두 실제 기능이 구현되어 있다.
- **상점**: 씨앗(당근 5코인 · 양배추 15코인), 고양이(샴 100,000 · 스핑크스 50,000 · 페르시안 500,000 · 러시안 블루 250,000 · 브리티시 쇼트헤어 250,000코인), 가구를 구매한다. 가구 탭은 제공된 256px 가구 에셋 39종을 상품으로 사용한다. 수량 선택 시 보유 코인 기준 최대 구매 가능 수량으로 채워주는 MAX 버튼 제공.
- **창고**: 씨앗/작물/가구 탭으로 나뉜다. 가구 탭에서 가구를 선택하면 집 맵으로 이동하고, 바닥 칸을 눌러 배치한다. 배치된 가구를 누르면 창고로 돌려놓는다.
- **도감**: 작물/고양이 목록. 고양이 항목을 누르면 보유 여부와 드랍 확률을 확인하고, 보유한 고양이로 밭에서 일하는 고양이를 바꿀 수 있다.
- **기록**: 이번 달 날짜별 타자 수를 잔디 히트맵으로 보여주고, 연속 기록일과 이번 달 누적 타자 수를 표시. 날짜를 누르면 해당 일자 타자 수 상세를 확인할 수 있다.

**맵 이동/집 꾸미기**: 확장 화면 맵의 왼쪽 버튼은 농장, 오른쪽 버튼은 집으로 이동한다. 버튼 아래의 목적지 아이콘과 하단 인디케이터로 현재 위치를 확인할 수 있다. 집 바닥은
`middle_wood_floor_256.png`를 반복해 채우며, 배치 결과는 `~/Library/Application Support/KeyCat/home.json`에 저장한다.

## 구조 (`Sources/KeyCat/`)
- `main.swift`: 메뉴바 앱 진입점
- `AppDelegate.swift`: 상태바 메뉴와 오버레이 패널
- `KeyCounter.swift`: 전역 키 입력 감지와 권한 처리
- `OverlayView.swift`: SwiftUI 오버레이 UI
- `Home.swift`: 집/가구 모델, 저장소, 내비게이션·집 바닥 뷰
- `FarmField.swift`: 농장 상태와 저장
- `ResourceBundle.swift`: Xcode/Swift Package 공용 리소스 접근

- Release 번들 ID와 Team이 본인 계정으로 설정되어 있는지 확인
- AppIcon이 올바르게 표시되는지 확인
- 입력 모니터링 권한 허용/거부 흐름을 실제 Mac에서 확인
- 다른 앱, 전체 화면, 여러 Space에서 오버레이 동작 확인
- Archive 결과가 Developer ID로 서명되고 공증되었는지 확인

앱 아이콘 원본은 `Artwork/AppIcon/keycat_app_icon.png`, Xcode용 크기별 결과는 `Sources/KeyCat/Assets.xcassets/AppIcon.appiconset`에서 관리합니다. 현재 원본은 512×512이며, 최종 배포 품질을 위해서는 1024×1024 이상 원본을 권장합니다.
