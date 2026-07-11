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
- `Package.swift`: 빠른 CLI 빌드와 기존 개발 흐름 호환

## 삭제 가능한 파일

- `.build`, `DerivedData`: 언제든 다시 생성되는 빌드 결과
- `xcuserdata`, `*.xcuserstate`: 개발자 개인 Xcode 상태
- `Documentation/Handoff`: 더 이상 참고하지 않는 시점에 전체 삭제 가능
- `Artwork/SourceAssets`: 최종 리소스 선별이 끝나고 원본 보관처가 따로 있을 때만 삭제 가능

`Sources/KeyCat/Resources`는 앱 실행에 필요하므로 삭제하면 안 됩니다.
