# typing-farm - 타이핑 농사 맥 오버레이 위젯 PoC

## 프로젝트 위치 / 브랜치
- 경로: `/Users/ujeonghyeon/Desktop/dev/myDev/typing-farm`
- 브랜치: `feat/overlay-keycount-poc` (main 미병합, main 브랜치 없음 - init 후 곧장 이 브랜치)
- 커밋 규칙: 한 프롬프트 = 한 의미 단위 커밋, Conventional Commits(`type: 요약`, 요약/본문 한글), em dash("-") 금지, co-author/서명 트레일러 없음

## 무엇을 만드는가
타이핑한 타자 수를 재화로 삼아 작물을 키우는 고양이 농장 맥 오버레이 위젯. 화면 구석에 항상 떠 있는 작은 창(축소)과 우측 패널(확장, 농장+상점/창고/도감/기록 탭) 구조. 원본 기획은 Figma(node 0:1, "이름뭘로할까여"). 현재는 **기술 검증 PoC 단계**로, 그래픽은 전부 회색/단색 박스 플레이스홀더.

## 이번 세션에서 확정한 결정 (중요)
- **네이티브 Swift(AppKit + SwiftUI)로 PoC 진행 확정.** Electron/Tauri 대안도 논의했으나 PoC는 네이티브로.
- **배포는 App Store 불가, 웹 직접 배포 전제.** 이유: "오늘 타자 수"에 필요한 전역 키 감지(CGEventTap)가 MAS 필수인 App Sandbox와 충돌(정책 문제, 우회 불가). 대신 Developer ID 서명 + 공증(notarization) 후 .dmg/.zip 웹 배포. 개인용은 서명/공증 불필요.
- **Xcode 프로젝트 대신 Swift Package(SPM)로 구성.** `swift run` 한 줄 실행/검증 목적. Swift 6.2 / Xcode 26.2 환경, tools-version 5.9(Swift 5 모드로 동시성 엄격성 회피).
- **PoC 범위는 리스크 2개 검증에 한정**: (1) 풀스크린 포함 항상-위 투명 오버레이, (2) 다른 앱 타자까지 세는 전역 카운트 + 필요 권한 확인. 농장 로직/재화/도감은 리스크 없는 일반 개발이라 PoC에서 제외.

## 재사용할 코어 / 건드리지 말 것
- `Sources/KeyCat/KeyCounter.swift` - CGEventTap(listen-only, cgSessionEventTap) 전역 keyDown 카운터. 권한 미허용 시 죽지 않고 2초 폴링으로 자동 재연결(`scheduleRetry`). PoC 핵심, 정식 버전에서도 코어로 재사용.
- `Sources/KeyCat/AppDelegate.swift` - `OverlayPanel`(borderless라 canBecomeKey override), `.floating` + `[.canJoinAllSpaces, .fullScreenAuxiliary]`, 우측상단 배치, 축소(230x230)/확장(405x838) 우측상단 모서리 고정 토글.
- `main.swift` - NSApplication `.accessory`(Dock 아이콘 없이 메뉴바 상주). 이 활성화 정책 유지할 것.

## 현재 상태
- 빌드: **통과** (`swift build`, 9초, 경고 없음)
- 실행 검증: **미검증** - 사용자가 아직 `swift run`으로 돌려 권한 허용/체크리스트 확인을 안 함. 다음 세션의 최우선 확인 대상.
- 테스트: 없음(PoC라 단위 테스트 미작성)
- 의존성: 없음(AppKit/SwiftUI/CoreGraphics 표준 프레임워크만)
- 커밋: `98349c2 feat: 오버레이 창 + 전역 타자 카운트 PoC 골격` 1개, 워킹트리 깨끗

## 다음에 할 일 (구현 단계)
1. **PoC 실행 검증** (사용자 주도, 대화형 권한 필요): `cd ~/Desktop/dev/myDev/typing-farm && swift run`. README.md 체크리스트로 확인:
   - 오버레이가 풀스크린 앱 위/Spaces 전환에 유지되는가, 드래그 이동 되는가
   - 요청 권한이 "입력 모니터링"인지 "손쉬운 사용"인지 실기기 확인 (PoC 핵심 수확)
   - 권한 허용 후 다른 앱 타이핑 시 카운트 오르는가
2. 검증 결과에 따라: 문제 있으면 KeyCounter/패널 설정 조정. 통과 시 다음 단계 진입.
3. (검증 통과 후) 실제 기능 설계 시작: 타자 수 -> 재화 환산, 작물 성장/수확 상태머신, 상점/창고/도감/기록 탭. Figma 원본(fileKey `HNnXSl2HgMR0yxQOFJWOjk`, node 0:1) 참조.
4. (배포 단계에서) `.app` 번들화 + Developer ID 서명 + 공증 파이프라인. `swift run` 권한 귀속 문제는 이때 해소됨.

## 제약 / 함정
- **권한 귀속**: `swift run`으로 실행하면 입력 모니터링 권한이 터미널/`.build` 바이너리에 붙는다. 정식 `.app` 번들과 다르게 뜰 수 있음 - 이 차이 자체가 PoC 확인 항목.
- **App Store 배포 불가 확정** - 웹 직접 배포 전제로 설계할 것. 재논의 불필요.
- 한글 입력/수정키(Shift 등) 카운트 방침 미결정 - 현재는 모든 keyDown 무조건 +1. 기능 설계 시 정할 것.
- Figma 그래픽(고양이/농장/작물)은 아직 미반영, 전부 플레이스홀더.
