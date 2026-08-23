# Repository Structure Decisions

## 정리 원칙

- 실행 코드와 런타임 리소스는 `Sources/KeyCat`에만 둔다.
- 원본 그래픽은 `Artwork/SourceAssets`에 보관하며 앱 타깃에 포함하지 않는다.
- 배포 설정은 `Config`에서 Debug/Release로 분리한다.
- Xcode 프로젝트와 Swift Package가 같은 Swift 소스를 공유한다.
- 생성물과 사용자별 Xcode 설정은 Git에 넣지 않는다.

## 유지하는 파일

- `KeyCat.xcodeproj`: macOS 앱 빌드와 Archive에 필요
- `Config/*.xcconfig`: 번들 ID, 버전, 배포 타깃 설정
- `Config/KeyCat.entitlements`: 코드 서명 entitlement 입력
- `Sources/KeyCat`: 제품 소스
- `Sources/KeyCat/Resources`: 제품에서 실제 사용하는 에셋과 폰트 라이선스
- `Sources/KeyCat/Resources/home`: 집 바닥 타일
- `Sources/KeyCat/Resources/furniture`: 상점에서 판매하는 개별 가구 PNG
- `Sources/KeyCat/Resources/navigation`: 맵 좌우 이동 버튼, 목적지 아이콘, 위치 인디케이터
- `Package.swift`: 빠른 CLI 빌드와 기존 개발 흐름 호환

## 삭제 가능한 파일

- `.build`, `DerivedData`: 언제든 다시 생성되는 빌드 결과
- `xcuserdata`, `*.xcuserstate`: 개발자 개인 Xcode 상태
- `Documentation/Handoff`: 더 이상 참고하지 않는 시점에 전체 삭제 가능
- `Artwork/SourceAssets`: 최종 리소스 선별이 끝나고 원본 보관처가 따로 있을 때만 삭제 가능

`Sources/KeyCat/Resources`는 앱 실행에 필요하므로 삭제하면 안 됩니다.

## 집 데이터

- 농장 상태는 `~/Library/Application Support/KeyCat/farm.json`에 저장한다.
- 집에 배치한 가구는 같은 디렉터리의 `home.json`에 저장한다.
- 씨앗/작물 보유 수량은 기존 앱 설정 저장 방식(UserDefaults)을 사용한다.
- 가구 보유 수량과 집 배치는 `home.json` 하나의 원자적 스냅샷으로 저장한다.
