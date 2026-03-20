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

2. **[필수] idb를 이용한 화면 조작 + 스크린샷 캡처:**

   코드 분석에서 발견된 화면/라우트를 **idb(iOS Development Bridge)로 직접 조작**하여 각 화면에 도달한 후 스크린샷을 캡처한다. 단순히 현재 보이는 화면만 찍는 것이 아니라, **코드에서 발견된 모든 화면을 idb로 네비게이션하여 반드시 캡처**해야 한다.

   - Flutter (iOS 시뮬레이터 — idb 사용):
     ```bash
     # idb 설치 확인
     idb --help 2>/dev/null || pip install fb-idb

     # 부팅된 시뮬레이터 확인
     idb list-targets

     # 화면 조작: 탭, 스와이프, 텍스트 입력
     idb ui tap {x} {y}                    # 좌표 탭
     idb ui swipe {x1} {y1} {x2} {y2}     # 스와이프 (스크롤)
     idb ui text "검색어"                   # 텍스트 입력
     idb ui key 4                          # 뒤로가기 등 키 입력
     idb ui button HOME                    # 홈 버튼

     # 스크린샷 캡처
     idb screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - Flutter (idb 없을 시 폴백):
     ```bash
     xcrun simctl io booted screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```
     이 경우 수동 네비게이션은 사용자에게 요청.

   - React/Next.js:
     - chrome-viewer: `cv_navigate` → `cv_click` → `cv_screenshot`
     - Playwright: `browser_navigate` → `browser_click` → `browser_take_screenshot`

   **필수 절차:**
   1. Phase 1에서 발견된 **모든 화면 목록**을 순회
   2. 각 화면에 idb 조작으로 도달 (탭 바 클릭, 버튼 탭, 스와이프 등)
   3. 도달 후 스크린샷 캡처
   4. 스크롤이 필요한 화면은 상단/하단 모두 캡처
   5. 상태별 화면(로딩, 에러, 빈 상태)도 가능하면 트리거하여 캡처

3. 각 스크린샷 Read → 시각 분석:
   - 레이아웃 구조: 헤더, 본문, 푸터, 하단 네비게이션 바 유무
   - 컴포넌트 유형: 카드, 리스트, 폼, 버튼, 아이콘, 모달
   - 색상 팔레트: 주요 색상, 배경색, 강조색 추출 (hex 코드)
   - 타이포그래피: 폰트 계열, 크기 체계
   - 현재 디자인 품질/문제점: 일관성, 공백, 정렬, 브랜딩 부재 등
   - **idb 조작 중 발견한 인터랙션 특성**: 전환 애니메이션, 제스처 반응, 로딩 타이밍

**Output:** 화면별 스크린샷 파일(`/tmp/analyze-*.png`) + 시각 분석 메모.

**Transition:** 코드에서 발견된 전체 화면의 스크린샷 캡처 및 분석 완료 시 Phase 3으로 이동.

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

## Phase 4: Feature별 UX-First 프롬프트 작성

**Goal:** 각 화면에 대해 Stitch AI의 창의성을 최대화하는 UX 중심 프롬프트를 작성한다.

**철학:** Vibe Design — AI에 자유도를 주되, 방향성은 명확히. 구현 디테일(px, hex, 폰트명)은 AI가 결정하도록 맡긴다.

**Steps:**

1. 참조 자료 확인:
   - `references/prompting.md` — UX-First 프롬프트 원칙 (이 문서가 최우선)

   > **⚠️ 중요**: 프롬프트에 hex 코드, px 값, 특정 폰트명을 포함하지 않는다.
   > `prompting.md`의 "Vibe Design 전략"을 따른다. 색상은 자연어("warm coral accent"),
   > 크기는 형용사("rounded corners", "generous spacing")로만 표현한다.

2. Feature별로 포함된 각 화면에 대해 UX-First 프롬프트 작성. 각 프롬프트는 아래 요소를 포함:

   - **화면 목적** (1줄): 사용자가 이 화면에서 달성하려는 것
     - 예: "기존 사용자가 빠르고 신뢰감 있게 앱에 접근"
   - **무드/바이브** (2-3 형용사): 화면의 분위기와 감정
     - 예: "warm, inviting, trustworthy" / "bold, energetic, modern"
   - **핵심 섹션** (번호 매긴 고수준 레이아웃):
     - 상단/중단/하단 영역을 자연어로 설명 (px, 패딩 값 없이)
     - 예: "1. Top: App branding  2. Center: Login form  3. Bottom: Alternative actions"
   - **UI 컴포넌트** (이름만 — 크기/색상 지정 안 함):
     - card, nav bar, CTA button, form field, icon 등
   - **사용자 흐름**: 이 화면에서 사용자가 하는 핵심 행동
     - 예: "이메일/비밀번호 입력 → 로그인 → 홈으로 이동"
   - **앱 컨텍스트**: 앱 이름, 카테고리 (reading tracker, fitness, etc.)
   - **플랫폼**: Mobile / Desktop / Tablet
   - **레퍼런스** (선택): "Similar to [known app]'s [screen]"
     - 예: "Similar to Goodreads' library view" / "Inspired by Spotify's Now Playing"
   - **제외 사항** (선택): 원하지 않는 요소 명시적 배제
     - 예: "No sidebar navigation" / "No gradient background"

3. **금지 사항** — 프롬프트에 절대 포함하지 않을 것:
   - ❌ hex 코드 (#FF6B6B, #FEFEFE 등)
   - ❌ px 값 (12px, 24px, 16px radius 등)
   - ❌ 특정 폰트명 (Inter, Poppins, Roboto 등)
   - ❌ border-radius, shadow, opacity 값
   - ❌ 정확한 간격/마진/패딩 수치

4. 프롬프트 품질 기준:
   - **분량**: 화면당 150-400자 (과도한 디테일은 AI 창의성 저하)
   - **언어**: 프롬프트 지시문은 영어로 작성
   - **한국어 UI 필수**: 모든 프롬프트 마지막에 반드시 아래 문구 포함:
     `All UI text, labels, buttons, placeholders, and content must be in Korean (한국어).`
   - **구조**: 자연스러운 문단 또는 짧은 bullet 형태
   - **복사 독립성**: 각 프롬프트가 다른 프롬프트 없이 단독으로 Stitch에 붙여넣기 가능

5. 각 화면에 **변형 아이디어** 2-3개 추가:
   - 나중에 `generate_variants`로 다양한 시안을 뽑기 위한 방향 메모
   - 예: "다크 모드 버전", "일러스트 배경", "미니멀 원페이지"

**Output:** 화면별 UX-First 프롬프트 + 변형 아이디어.

**Transition:** 전체 화면 프롬프트 작성 완료 시 Phase 5로 이동.

## Phase 5: 산출물 작성

**Goal:** 분석 결과를 단일 마크다운 파일로 작성하고 사용자 확인을 받는다.

**Steps:**

1. 파일 경로: `.stitch/{date}-{app}-analysis.md`

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
   - "분석 결과를 `.stitch/{date}-{app}-analysis.md`에 저장했습니다. 검토 후 `/stitch design [feature]`로 디자인 생성을 시작하세요."

**Output:** `.stitch/{date}-{app}-analysis.md` — Feature 전체와 Stitch 프롬프트 포함 단일 파일.

**Transition:** 사용자가 확인하면 파이프라인 완료. `/stitch design [feature]` 실행 시 analysis.md를 입력으로 사용 (Phase 1-3 생략, Phase 4부터 시작).
