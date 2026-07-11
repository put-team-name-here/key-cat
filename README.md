# KeyCat

타이핑으로 농사짓는 macOS 메뉴바 오버레이 앱입니다. macOS 14 이상을 지원합니다.

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

Swift Package 경로도 유지되어 있습니다.

```sh
swift run
```

배포 및 권한 검증은 반드시 Xcode에서 생성한 `.app`으로 수행합니다.

## 주요 파일

- `main.swift`: 메뉴바 앱 진입점
- `AppDelegate.swift`: 상태바 메뉴와 오버레이 패널
- `KeyCounter.swift`: 전역 키 입력 감지와 권한 처리
- `OverlayView.swift`: SwiftUI 오버레이 UI
- `FarmField.swift`: 농장 상태와 저장
- `ResourceBundle.swift`: Xcode/Swift Package 공용 리소스 접근

## 배포 전 확인

- Release 번들 ID와 Team이 본인 계정으로 설정되어 있는지 확인
- 앱 아이콘 추가 여부 확인
- 입력 모니터링 권한 허용/거부 흐름을 실제 Mac에서 확인
- 다른 앱, 전체 화면, 여러 Space에서 오버레이 동작 확인
- Archive 결과가 Developer ID로 서명되고 공증되었는지 확인

현재 앱 아이콘은 별도 Asset Catalog가 없어 기본 아이콘으로 빌드됩니다. 최종 배포 전 1024×1024 원본으로 AppIcon을 추가해야 합니다.
