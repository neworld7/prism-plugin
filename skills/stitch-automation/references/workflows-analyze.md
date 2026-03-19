# Analyze Pipeline (workflows-analyze)

Phase 1-5 execution guide for `/stitch analyze [app]`.

## Phase 1: 코드 분석

**Goal:** 프로젝트 소스 코드에서 모든 화면, 인터랙션, 상태를 추출한다.

**Steps:**

1. 프로젝트 스택 판별:
   - Flutter: `Glob: lib/**/*.dart`
   - React: `Glob: src/**/*.{tsx,jsx}`
   - Next.js: `Glob: app/**/*.{tsx,jsx}`

2. 화면/페이지 추출:
   - Flutter: `Grep: class.*Screen|class.*Page|class.*View` in `lib/`
   - React/Next: `Grep: export default|export function` in page files

3. 라우트/네비게이션 구조:
   - Flutter: `Grep: GoRoute|MaterialPageRoute|Navigator.push`
   - React/Next: 파일 기반 라우팅 or `Grep: useRouter|Link`

4. 인터랙션 추출:
   - `Grep: onTap|onPressed|onClick|onSubmit|GestureDetector`

5. 상태 추출:
   - `Grep: Loading|Error|Empty|CircularProgressIndicator|Shimmer|skeleton`

**Output:** 화면 목록, 인터랙션 목록, 상태 목록 → 다음 Phase로 전달.

**Transition:** 코드 분석 완료 시 Phase 2로 이동.

## Phase 2: 시뮬레이터 스크린샷 캡처 및 분석

**Goal:** 실제 실행 화면을 캡처하고 시각적으로 분석하여 현재 디자인 상태를 파악한다.

**Steps:**

1. 앱 실행 확인:
   - Flutter: iOS 시뮬레이터 또는 Android 에뮬레이터 실행 여부 확인
   - React/Next.js: dev 서버 실행 여부 확인 (`localhost:{port}`)
   - 미실행 시 사용자에게 앱 실행 요청

2. 화면별 스크린샷 캡처:
   - Flutter:
     ```bash
     xcrun simctl io booted screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```
     각 화면으로 네비게이션 후 캡처 반복
   - React/Next.js:
     - chrome-viewer: `cv_screenshot` (현재 탭 캡처)
     - Playwright: `browser_take_screenshot`
     각 라우트로 이동 후 캡처 반복

3. 각 스크린샷 Read → 시각 분석:
   - 레이아웃 구조: 헤더, 본문, 푸터, 하단 네비게이션 바 유무
   - 컴포넌트 유형: 카드, 리스트, 폼, 버튼, 아이콘, 모달
   - 색상 팔레트: 주요 색상, 배경색, 강조색 추출
   - 타이포그래피: 폰트 계열, 크기 체계
   - 현재 디자인 품질/문제점: 일관성, 공백, 정렬, 브랜딩 부재 등

**Output:** 화면별 스크린샷 파일(`/tmp/analyze-*.png`) + 시각 분석 메모.

**Transition:** 전체 화면 캡처 및 분석 완료 시 Phase 3으로 이동.

## Phase 3: Feature 분리

**Goal:** 코드 분석 + 스크린샷 분석 결과를 종합하여 Feature 단위로 화면을 분류한다.

**Steps:**

1. Phase 1 코드 분석 결과와 Phase 2 시각 분석 결과를 종합

2. 화면을 기능 단위(Feature)로 그룹화:
   ```
   예시:
   Feature 1: 인증 (로그인, 회원가입, 비밀번호 재설정)
   Feature 2: 홈 대시보드 (메인 피드, 알림, 퀵 액션)
   Feature 3: 라이브러리 (목록, 검색, 필터, 상세)
   Feature 4: 프로필 (설정, 통계, 편집)
   ```

3. 각 Feature에 매핑:
   - 포함 화면 목록 (코드 파일 경로 포함)
   - 해당 Feature의 인터랙션
   - 해당 Feature의 상태 (로딩/에러/빈 상태)

**Output:** Feature 목록 + 화면/인터랙션/상태 매핑 구조.

**Transition:** Feature 분리 완료 시 Phase 4로 이동.

## Phase 4: Feature별 상세 프롬프트 작성

**Goal:** 각 화면에 대해 PRO 원샷 품질의 Stitch 프롬프트를 작성한다.

**Steps:**

1. 참조 자료 확인:
   - `references/official/enhance-prompt/` — Stitch 공식 프롬프트 강화 가이드
   - `references/prompting.md` — 프롬프트 작성 원칙

2. Feature별로 포함된 각 화면에 대해 상세 프롬프트 작성:
   - **화면 목적**: 페이지 유형 명시 (login screen, dashboard, list view 등)
   - **핵심 UI 컴포넌트 목록**: nav bar, cards, buttons, forms, icons 등 구체적 열거
   - **레이아웃/구조 명세**: 상단/중단/하단 영역 구성, 그리드, 패딩
   - **스타일/테마 지시**: Phase 2 스크린샷에서 추출한 색상(hex 코드), 분위기, 무드
   - **동적 콘텐츠 유형**: 리스트 아이템, 카드 콘텐츠, 빈 상태 메시지
   - **브랜딩**: 앱 이름, 로고 위치, 아이콘 스타일
   - **디바이스 타입**: Flutter → `MOBILE`, 웹 → `DESKTOP` (태블릿 시 `TABLET`)

3. PRO 원샷 품질 목표:
   - 한 번의 생성으로 완성도 높은 결과가 나오도록 충분히 상세하게 작성
   - 모호한 표현 금지 — 구체적인 색상값, 크기, 컴포넌트명 사용
   - 스크린샷 분석 결과를 프롬프트에 반영하여 현재 앱 분위기와 일치시킴

**Output:** 화면별 최적화된 Stitch 프롬프트 초안.

**Transition:** 전체 화면 프롬프트 작성 완료 시 Phase 5로 이동.

## Phase 5: 산출물 작성

**Goal:** 분석 결과를 단일 마크다운 파일로 작성하고 사용자 확인을 받는다.

**Steps:**

1. 파일 경로: `docs/plans/{date}-{app}-analysis.md`

2. 아래 템플릿 구조에 따라 작성:

```markdown
# {App} Analysis

| 항목 | 값 |
|------|------|
| App | {app name} |
| Date | {YYYY-MM-DD} |
| Stack | Flutter / React / Next.js |
| Device | Mobile / Desktop / Tablet |
| Total Features | N |
| Total Screens | N |

## Feature 요약

| # | Feature | 화면 수 | 핵심 화면 |
|---|---------|---------|-----------|
| 1 | 인증 | 3 | 로그인, 회원가입, 비밀번호 재설정 |
| 2 | 홈 | 2 | 대시보드, 알림 |
| ... | ... | ... | ... |

## Feature 1: {feature name}

### 화면 목록

| # | 화면 | 코드 파일 | 현재 상태 | 스크린샷 분석 요약 |
|---|------|-----------|-----------|-------------------|
| 1 | 로그인 | lib/.../login_screen.dart | 기본 폼 | 단순 이메일/비밀번호, 브랜딩 없음 |

### 인터랙션

- [ ] 이메일/비밀번호 입력
- [ ] 로그인 버튼 → 홈으로 이동
- [ ] "비밀번호 찾기" 링크
- [ ] 소셜 로그인 버튼

### 상태별 화면

| 상태 | 설명 |
|------|------|
| 로딩 | 로그인 처리 중 스피너 |
| 에러 | 잘못된 자격 증명 메시지 |

### Stitch 프롬프트

#### {screen name}
```
Design a mobile login screen for a reading tracker app called 'ReadCodex'.
Center: App logo with tagline "Track your reading journey".
Form: Email field with envelope icon, password field with eye toggle,
rounded input borders (12px), subtle shadow on focus.
Below form: "Forgot password?" link in muted text.
Primary CTA: "Sign In" button, full-width, coral (#FF6B6B) background,
white text, rounded (24px).
Bottom: "Don't have an account? Sign up" with link highlight.
Social login section: Google and Apple sign-in buttons with brand icons,
outlined style.
Use warm white (#FEFEFE) background, serif font for logo,
sans-serif (Inter) for body. iOS-style with safe area padding.
```

#### {screen name 2}
```
...
```

## Feature 2: {feature name}
...
```

3. 파일 작성 완료 후 **사용자 확인 요청**:
   - "분석 결과를 `docs/plans/{date}-{app}-analysis.md`에 저장했습니다. 검토 후 `/stitch design [feature]`로 디자인 생성을 시작하세요."

**Output:** `docs/plans/{date}-{app}-analysis.md` — Feature 전체와 Stitch 프롬프트 포함 단일 파일.

**Transition:** 사용자가 확인하면 파이프라인 완료. `/stitch design [feature]` 실행 시 analysis.md를 입력으로 사용 (Phase 1-3 생략, Phase 4부터 시작).
