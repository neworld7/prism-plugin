# Prism Workflows

통합 워크플로우 실행 가이드. Analyze (A1-A6) → Design (D1-D6).

## Analyze Pipeline — `/prism analyze [app]`

### A1: 코드 분석 (심층)

**Goal:** 프로젝트 소스 코드에서 **모든 화면, 서브 화면, 모달, 바텀시트, 상태 변형**을 빠짐없이 추출한다.

**Steps:**

1. 프로젝트 스택 판별:
   - Flutter: `Glob: lib/**/*.dart`
   - React: `Glob: src/**/*.{tsx,jsx}`
   - Next.js: `Glob: app/**/*.{tsx,jsx}`

**Screen State Matrix 6축에 대응하는 코드 패턴을 모두 추출한다:**

#### 축 1: Primary Screens
```
Flutter: Grep: class.*Screen|class.*Page in lib/
Flutter: Grep: GoRoute|path: in router file (라우트 구조)
React/Next: Grep: export default|export function in page files
```

#### 축 2: Screen States
```
# 빈 상태 (empty)
Grep: empty.*state|EmptyState|no.*data|아직.*없|등록된.*없|검색.*결과.*없|없어요|없습니다

# 로딩/스켈레톤 (loading/skeleton)
Grep: CircularProgressIndicator|Shimmer|skeleton|loading|Loading|isLoading|shimmer

# 에러 (error)
Grep: error.*widget|ErrorWidget|오류|실패|Error.*state|hasError|onError

# 데이터 있음 (populated) — 코드 분석 불필요, 메인 화면이 이 상태
```

#### 축 3: Overlays
```
# 모달/바텀시트
Grep: showModalBottomSheet|showBottomSheet|BottomSheet|showDialog

# 다이얼로그/확인
Grep: AlertDialog|SimpleDialog|showDialog|confirm|삭제.*할까|정말

# 스낵바/토스트
Grep: ScaffoldMessenger|showSnackBar|SnackBar|Toast|toast

# 드로어
Grep: Drawer|showDrawer|endDrawer

# 팝오버/툴팁/메뉴
Grep: PopupMenuButton|showMenu|Tooltip|DropdownButton
```

#### 축 4: Interaction Modes
```
# 편집/선택 모드
Grep: _isEditMode|editMode|isEditing|_isSelecting|selectionMode

# 드래그/리오더
Grep: ReorderableListView|Draggable|DragTarget|onReorder|LongPressDraggable

# 스와이프 액션
Grep: Dismissible|SwipeAction|slidable

# 검색 활성
Grep: _focusNode|searchFocus|isSearching|SearchDelegate|showSearch

# 키보드/입력 포커스
Grep: TextEditingController|FocusNode|_controller|autofocus
```

#### 축 5: System States
```
# 스플래시
Grep: SplashScreen|native_splash|launch_screen

# 권한 요청
Grep: Permission|permission|openAppSettings|requestPermission|getToken

# 오프라인/네트워크
Grep: connectivity|isOffline|noInternet|NetworkException|Connectivity

# 강제 업데이트
Grep: forceUpdate|appUpdate|remote_config|version.*check

# 딥링크
Grep: deepLink|universalLink|dynamicLink|incoming.*link
```

#### 축 6: Transitions
```
# 온보딩/투어
Grep: Onboarding|onboarding|tutorial|coach|walkthrough|firstLaunch|isFirst

# 완료/축하
Grep: Completion|celebration|congrat|완료|축하|성공

# 인터랙션
Grep: onTap|onPressed|onClick|onSubmit|onLongPress|GestureDetector
```

**각 축에서 발견된 코드 위치를 아래 형식으로 정리**하여 A3의 입력 데이터로 사용한다.

**Output 형식 (A1 → A3 전달 구조):**

```markdown
## A1 코드 분석 결과

### 축 1: Primary Screens (N개)
| # | 화면 클래스 | 파일 경로 | 라우트 |
|---|-----------|----------|-------|
| 1 | LoginScreen | auth/login_screen.dart | /login |

### 축 2: Screen States (N개)
| # | 상태 유형 | 발견 위치 | 관련 화면 |
|---|---------|----------|----------|
| 1 | empty | bookshelf_tab.dart:1032 "아직 등록된 책이 없어요" | 서재 |

### 축 3: Overlays (N개)
| # | 오버레이 유형 | 발견 위치 | 관련 화면 | 용도 |
|---|------------|----------|----------|------|
| 1 | bottom-sheet | book_detail_screen.dart:397 showModalBottomSheet | 책 상세 | 읽기 상태 변경 |

### 축 4: Interaction Modes (N개)
| # | 모드 | 발견 위치 | 관련 화면 |
|---|-----|----------|----------|
| 1 | edit-mode | bookshelf_tab.dart:36 _isEditMode | 서재 |

### 축 5: System States (N개)
| # | 상태 | 발견 위치 |
|---|-----|----------|
| 1 | permission | push_notification_service.dart getToken |

### 축 6: Transitions (N개)
| # | 전환 | 발견 위치 |
|---|-----|----------|
| 1 | onboarding | onboarding_screen.dart |
```

**중요:** 표가 비어있는 축도 반드시 포함한다. 빈 축은 A3에서 "코드에는 없지만 앱에 필요한 화면"을 추가하는 힌트가 된다.

### A2: 시뮬레이터 스크린샷 캡처 및 분석

**Goal:** 실제 실행 화면을 캡처하고 시각적으로 분석하여 현재 디자인 상태를 파악한다.

**Steps:**

1. 앱 실행 확인:
   - Flutter: iOS 시뮬레이터 또는 Android 에뮬레이터 실행 여부 확인
   - React/Next.js: dev 서버 실행 여부 확인 (`localhost:{port}`)
   - 미실행 시 사용자에게 앱 실행 요청

2. **[필수] idb를 이용한 화면 조작 + 스크린샷 캡처:**

   코드 분석에서 발견된 화면/라우트를 **idb(iOS Development Bridge)로 직접 조작**하여 각 화면에 도달한 후 스크린샷을 캡처한다.

   - Flutter (iOS 시뮬레이터 — idb 사용):
     ```bash
     idb --help 2>/dev/null || pip install fb-idb
     idb list-targets
     idb ui tap {x} {y}
     idb ui swipe {x1} {y1} {x2} {y2}
     idb ui text "검색어"
     idb screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - Flutter (idb 없을 시 폴백):
     ```bash
     xcrun simctl io booted screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - React/Next.js:
     - chrome-viewer: `cv_navigate` → `cv_click` → `cv_screenshot`
     - Playwright: `browser_navigate` → `browser_click` → `browser_take_screenshot`

   **필수 절차:**
   1. A1에서 발견된 **모든 화면 목록**을 순회
   2. 각 화면에 idb 조작으로 도달
   3. 도달 후 스크린샷 캡처
   4. 스크롤이 필요한 화면은 상단/하단 모두 캡처
   5. 상태별 화면(로딩, 에러, 빈 상태)도 가능하면 트리거하여 캡처

3. 각 스크린샷 Read → 시각 분석:
   - 레이아웃 구조, 컴포넌트 유형, 색상 팔레트, 타이포그래피
   - 현재 디자인 품질/문제점
   - idb 조작 중 발견한 인터랙션 특성

**Output:** 화면별 스크린샷 + 시각 분석 메모.

### A3: Feature 분리 (심층 — 서브 화면 포함)

**Goal:** 코드 분석 + 스크린샷 분석 결과를 종합하여 Feature 단위로 **모든 화면과 상태 변형**을 빠짐없이 분류한다.

**Steps:**

1. 화면을 기능 단위(Feature)로 그룹화
2. 각 Feature의 화면을 **Screen State Matrix**로 분해한다. 모든 축을 검토하여 빠진 화면이 없는지 확인한다:

**Screen State Matrix — 모바일 앱 화면 분류 체계:**

| 축 | 분류 | 포함 항목 |
|---|------|----------|
| **Primary Screens** | 라우트가 있는 독립 화면 | 메인 화면, 상세 화면, 폼/에디터, 설정 하위 화면 |
| **Screen States** | 같은 화면의 상태 변형 | `empty` (데이터 없음), `loading` (스켈레톤/시머), `error` (에러 표시), `populated` (데이터 있음), `disabled` (비활성), `skeleton` (초기 로딩) |
| **Overlays** | 화면 위에 뜨는 UI | `modal`, `bottom-sheet`, `dialog` (확인/삭제), `snackbar/toast`, `tooltip`, `popover`, `drawer`, `action-sheet`, `context-menu` |
| **Interaction Modes** | 사용자 인터랙션에 의한 모드 전환 | `edit-mode`, `selection-mode`, `drag-reorder`, `swipe-actions`, `long-press-menu`, `keyboard-up` (입력 포커스), `search-active` (검색 활성), `filter-panel` |
| **System States** | 앱/OS 수준 상태 | `splash`, `permission-prompt` (알림/카메라), `offline-banner`, `force-update`, `deep-link-landing`, `app-review-prompt` |
| **Transitions** | 화면 간 전환/가이드 | `onboarding-tour`, `coach-marks`, `walkthrough`, `completion-celebration`, `first-use-hint` |

**적용 방법:**
각 Feature의 Primary Screen마다 위 매트릭스를 적용하여 필요한 화면을 도출한다.

```
예시 — "서재" Primary Screen 분해:
- Primary: 서재 (책장, 그리드 뷰), 서재 (리스트 뷰), 서재 (읽고 있는 책)
- Screen States: 서재 (empty), 서재 (skeleton loading)
- Overlays: 정렬/필터 바텀시트, 책 삭제 확인 다이얼로그
- Interaction Modes: 서재 (edit mode + 선택 바), 서재 (search active + 키보드)
- Transitions: 서재 첫 방문 코치마크
```

3. **코드에 없더라도 앱에 필수적인 화면은 추가한다:**
   - A1에서 `offline` 패턴이 발견되지 않아도 → "오프라인 배너" 화면은 추가
   - A1에서 `skeleton` 패턴이 없어도 → 주요 화면의 "로딩 스켈레톤" 화면은 추가
   - A1에서 `splash` 패턴이 없어도 → "스플래시 스크린" 화면은 추가
   - A1에서 `snackbar` 패턴이 없어도 → 주요 액션의 "피드백 토스트" 화면은 추가
   - 이는 **디자인 완성도**를 위한 것이며, 코드 존재 여부와 무관하다.

4. **화면 수 목표**: Feature당 최소 5개 이상. **개발자가 바로 코드로 옮길 수 있는 수준**의 모든 상태를 커버해야 한다. 전체 앱 기준 40~60개 화면.
5. 각 Feature에 매핑: 포함 화면 목록 (축 태그 포함), 인터랙션, 상태

**Output:** Feature 목록 + Screen State Matrix 기반 화면 목록 (전체 40~60개). 각 화면에 해당 축 태그를 표시한다:

```markdown
| # | 화면 | 축 태그 | 소스 |
|---|------|--------|------|
| 1 | 서재 (책장, 데이터 있음) | Primary | 코드 발견 |
| 2 | 서재 (빈 상태) | Screen States: empty | 코드 발견 |
| 3 | 서재 (스켈레톤 로딩) | Screen States: skeleton | 디자인 필수 추가 |
| 4 | 서재 (편집 모드) | Interaction: edit-mode | 코드 발견 |
| 5 | 정렬/필터 바텀시트 | Overlay: bottom-sheet | 코드 발견 |
| 6 | 오프라인 배너 | System: offline | 디자인 필수 추가 |
```

### A4: Feature별 원시 프롬프트 작성

**Goal:** 각 화면(메인 + 서브 + 모달 + 상태)에 대해 UX 중심 프롬프트 초안을 작성한다.

**철학:** Vibe Design — AI에 자유도를 주되 방향성은 명확히. 구현 디테일은 AI가 결정.

**프롬프트 요소:**
- 화면 목적 (1줄)
- 무드/바이브 (2-3 형용사)
- 핵심 섹션 (번호 매긴 고수준 레이아웃)
- UI 컴포넌트 (이름만)
- 사용자 흐름
- 앱 컨텍스트, 플랫폼, 레퍼런스, 제외 사항

**서브 화면 프롬프트 작성 규칙:**

모든 서브 화면에도 별도 프롬프트를 작성한다:

```
예시 — Library Feature:
1. 서재 (책장, 데이터 있음) — 2열 그리드에 책 8권
2. 서재 (책장, 빈 상태) — "아직 등록된 책이 없어요" + 추가 CTA
3. 서재 (읽고 있는 책) — 커버 캐러셀 + 진행률
4. 서재 (읽고 있는 책, 빈 상태) — "현재 읽고 있는 책이 없어요"
5. 서재 (편집 모드) — 체크박스 + 삭제/태그 하단 바
6. 서재 (리스트 뷰) — 리스트 형태 전환
7. 책 추가 — 3가지 옵션 카드
8. 책 검색 (결과 있음) — 검색 결과 4개
9. 책 검색 (결과 없음) — "검색 결과가 없습니다"
10. 책 등록 폼 — 제목/저자/페이지수 입력
```

**A4 원시 프롬프트 규칙 (디자인 시스템 미포함):**
- ❌ hex 코드, px 값, 특정 폰트명 — A4는 UX/구조만 기술
- ❌ border-radius, shadow, opacity 수치
- ✅ 디자인 시스템(DESIGN.md)의 색상/폰트는 **A5 최적화 단계**에서 삽입됨
- ✅ A4는 "무엇을 보여줄지"에 집중, "어떻게 보일지"는 A5+D2에서 처리

**품질 기준:**
- 화면당 150-400자
- 프롬프트 지시문은 영어
- 마지막에 반드시: `All UI text, labels, buttons, placeholders, and content must be in Korean (한국어).`

**Output:** Feature별 원시 UX-First 프롬프트 (전체 40개+). 디자인 시스템 토큰은 미포함.

### A4.5: Direction 생성 (멀티 모드 전용)

> `--directions 1`이면 이 단계를 건너뛴다. Direction은 `default`로 자동 설정.

**Goal:** `--directions N` (N >= 2)일 때, 3축 기반으로 **N × 3개** 디자인 방향 시안을 제시하고, 사용자가 그중 **N개를 선택**한다.

**시안 수 규칙:** `--directions N` → **N × 3개** 시안 생성 → 사용자가 N개 선택
- `--directions 1` → 3개 시안 → 1개 선택
- `--directions 2` → 6개 시안 → 2개 선택
- `--directions 3` → 9개 시안 → 3개 선택

**3축 프레임워크:**

| 축 | 역할 | 예시 값 |
|---|---|---|
| **아키타입** | 전체 디자인 언어 결정 | Editorial Elegance, Flat Modern, Glassmorphism, Dark Minimalism, Playful Pastel, Japanese Zen, Warm Organic |
| **레이아웃** | 화면 구조/배치 패턴 | Centered Stack, Split Screen, Bottom Sheet, Full-bleed Hero, Card-based, Centered Narrow |
| **레퍼런스 앱** | AI가 참조할 구체적 디자인 DNA | Notion, Linear, Stripe, Duolingo, Airbnb, 밀리의서재, Spotify |

**시안 다양성 규칙:** N × 3개 시안은 서로 충분히 다른 방향이어야 한다. 아키타입, 레이아웃, 레퍼런스 축에서 최대한 중복을 피한다.

**출력 형식:**

```
📐 시안 1: "{Direction 이름}"
  아키타입: {아키타입} — {핵심 특성 1줄}
  레이아웃: {레이아웃} — {구조 설명 1줄}
  레퍼런스: {레퍼런스 앱} — {해당 앱의 어떤 측면을 참조하는지}

  {이 방향이 앱에 적합한 이유 2-3줄.}

📐 시안 2: ...
...
📐 시안 {N×3}: ...

→ 위 {N×3}개 시안 중 {N}개를 선택해주세요. (예: "1, 5, 7")
```

**사용자 응답 처리:**
- "1, 5, 7" → 선택된 시안을 Direction으로 확정, A5로 진행
- "3번을 X로 바꿔주세요" → 교체 후 재표시
- "하나 더 추가" → 추가 시안 생성
- 숫자만 응답 → 해당 시안 선택

### A5: 프롬프트 최적화 — 공식 스킬 위임

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

**단일 모드 (--directions 1):**
```
Skill("enhance-prompt") 호출 1회
→ A4에서 작성한 원시 프롬프트를 전달
→ 결과를 .prism/directions/default/prompts.md에 저장
```

**멀티 모드 (--directions N):**
```
각 Direction에 대해 Skill("enhance-prompt") 호출:
→ 원시 프롬프트 + Direction Context 블록 삽입
→ 결과를 .prism/directions/{direction-name}/prompts.md에 저장
```

**Direction Context 삽입 예시:**
```
원시 프롬프트 앞에 삽입:

**Direction: Cozy Reading Nook**
- Archetype: Warm Organic — natural textures, paper-like, serif typography
- Layout: Centered Generous — ample margins, vertical stack
- Reference: Inspired by 밀리의서재's warm, trustworthy onboarding
```

### A6: 산출물 저장

**Goal:** 분석 결과를 저장하고 사용자 확인을 받는다.

**파일 구조 (단일/멀티 동일):**

```
.prism/
  analysis.md                    ← 공통 (A1-A4 산출물)
  directions/
    default/                     ← 단일 모드
      prompts.md                 ← A5 결과
    {direction-name}/            ← 멀티 모드
      prompts.md                 ← A5 결과
```

**analysis.md 템플릿:**

```markdown
# {App} Analysis

| 항목 | 값 |
|------|------|
| App | {app name} |
| Date | {YYYY-MM-DD} |
| Stack | Flutter / React / Next.js |
| Device | Mobile / Desktop / Tablet |
| Total Features | N |
| Total Screens | N (메인 + 서브 + 모달 + 상태 변형 모두 포함) |

## 앱 컨텍스트

> {앱의 목적, 타겟 사용자, 전반적 분위기를 2-3줄로 요약}

## Feature 요약

| # | Feature | 화면 수 | 핵심 화면 |
|---|---------|---------|-----------|
| 1 | 인증 | 6 | 로그인, 회원가입, 비밀번호 재설정, 로딩, 에러 |

## Feature 1: {feature name}

### 화면 목록

| # | 화면 | 유형 | 코드 파일 | 현재 상태 |
|---|------|------|-----------|-----------|
| 1 | 로그인 | 메인 | login_screen.dart | 기본 폼 |
| 2 | 로그인 에러 | 에러 | login_screen.dart | 유효성 에러 표시 |
| 3 | 비밀번호 재설정 | 모달 | login_screen.dart | 바텀시트 |

### 사용자 흐름

이메일/비밀번호 입력 → 로그인 → (에러 시) 에러 메시지 → (성공 시) 홈으로 이동
```

**prompts.md 템플릿 (Direction별):**

```markdown
# Direction: {Direction 이름}

아키타입: {아키타입} / 레이아웃: {레이아웃} / 레퍼런스: {레퍼런스}

## Feature 1: {feature name}

### 🎯 로그인
📋 **Stitch 프롬프트**
(enhance-prompt 결과)

### 🎯 로그인 에러 상태
📋 **Stitch 프롬프트**
(enhance-prompt 결과)
```

---

## Design Pipeline — `/prism design <feature|all>`

### Direction Routing

1. `.prism/directions/` 에서 현재 Direction 디렉토리 확인
2. 해당 Direction의 `prompts.md`에서 Feature 프롬프트 로드
3. 해당 Direction의 `DESIGN.md`를 `./DESIGN.md`로 복원 (첫 Feature 이후)

### Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 건너뛴다.

1. Read `.claude/prism-design-pipeline.local.md` → `feature` 필드 확인
2. 현재 Direction의 prompts.md에서 해당 Feature 프롬프트만 추출

### D1: prompts.md 로드

**Goal:** 현재 Direction의 프롬프트를 로드한다.

**Steps:**
1. `.prism/directions/{direction}/prompts.md` 존재 확인
2. 없으면 `/prism analyze` 먼저 실행 안내
3. 있으면 해당 Feature의 프롬프트 로드

### D2: 디자인 시스템 — DESIGN.md 일관성 보장

**Goal:** 모든 Feature 프로젝트에 동일한 디자인 시스템을 적용한다.

**⚠️ 핵심 규칙: Feature별 프로젝트를 분리하되, 디자인 시스템(DESIGN.md)은 반드시 동일해야 한다.**

**첫 Feature에서:**
```
Skill("design-md") 호출 → ./DESIGN.md 생성
원본 보존: cp ./DESIGN.md .prism/directions/{direction}/DESIGN.md
```

**이후 Feature에서 (같은 Direction):**
```
.prism/directions/{direction}/DESIGN.md를 ./DESIGN.md로 복원
D2 재호출 불필요 — 동일 DESIGN.md가 새 프로젝트에도 적용됨
```

**Direction 전환 시:**
```
새 Direction의 첫 Feature → D2 재호출 → DESIGN.md 새로 생성 → 보존
```

**DESIGN.md 적용 방법:**
Stitch `create_project` 시 DESIGN.md의 핵심 토큰(색상, 폰트, roundness)을 프로젝트 설정에 반영하고,
`generate_screen_from_text` 프롬프트에 DESIGN.md 내용을 포함하여 디자인 일관성을 보장한다.

### D3: 디자인 생성 — Feature별 프로젝트

**Goal:** Feature 프롬프트로 Stitch 디자인을 생성한다.

**⚠️ 프로젝트 구조: Feature별 프로젝트 분리**

```
Feature별로 별도 Stitch 프로젝트를 생성한다:
→ 프로젝트 이름: "{App} — {Direction} — {Feature번호}. {Feature명}"
→ 예시: "ReadCodex — Cozy — 1. Auth & Onboarding"
→ 예시: "ReadCodex — Cozy — 2. Library"
→ 각 프로젝트에 해당 Feature의 모든 화면 (메인 + 서브 + 모달 + 상태)을 생성
→ 생성된 프로젝트 ID를 .prism/directions/{direction}/project-ids.md에 기록
```

**실행:**
```
1. create_project 호출 → 프로젝트 생성 (프로젝트 이름에 Feature 포함)
2. 해당 Feature의 모든 화면 프롬프트를 순차 생성
3. 각 화면: generate_screen_from_text 호출 (1회만)
4. 생성 확인 후 다음 화면으로
```

**모델 강제 규칙:**
`generate_screen_from_text` 호출 시 반드시 `modelId: "GEMINI_3_1_PRO"`를 명시한다.

**⚠️ Stitch API 중복 생성 방지 규칙 (필수):**

Stitch `generate_screen_from_text`는 비동기적으로 동작한다. 다음 규칙을 반드시 지킨다:

1. **"no output" 응답 ≠ 실패** — API가 `(completed with no output)`을 반환해도 화면이 생성되었을 수 있다. **절대 즉시 재시도하지 않는다.**

2. **생성 확인은 `get_project`로** — `list_screens`는 빈 결과를 반환할 수 있으므로 사용하지 않는다. 대신 `get_project`의 `screenInstances` 배열에서 실제 화면 수를 확인한다.

3. **생성 후 확인 절차:**
   ```
   generate_screen_from_text 호출 (1회만)
   ↓
   outputComponents 있으면 → 성공, screenId 기록
   outputComponents 없으면 ("no output") → 15초 간격 폴링 시작 (최대 60초)
   ↓
   매 15초마다 get_project → screenInstances 배열 확인
   ↓
   화면 수 증가 감지 → 즉시 성공 처리, 새 screenId 확인
   60초까지 미증가 → 1회만 재시도 (최대)
   ```

4. **재시도 전 중복 체크** — 같은 title의 화면이 `screenInstances`에 이미 존재하면 재생성하지 않는다.

5. **화면 수 기록** — 각 생성 호출 전에 `get_project`로 현재 `screenInstances.length`를 기록해두어 생성 후 비교한다.

### D4: 검증

**실행 주체:** loom 자체 (읽기 전용 MCP 직접 호출)

**Steps:**
1. 각 화면에 대해:
   ```
   get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/prism-{screenName}.png
   sips -Z 1200 /tmp/prism-{screenName}.png
   Read /tmp/prism-{screenName}.png → 시각 검증
   ```

2. 체크리스트 + gaps 카운트

**Transition:** gaps == 0 → D6, gaps > 0 → D5.

### D5: 수정 — 공식 스킬 위임

```
Skill("stitch-design") 호출
→ 수정 프롬프트 전달
```
**Transition:** D4로 복귀.

### D6: 완료

1. `<promise>DESIGN_VERIFIED</promise>` 출력
2. Stop hook이 감지:
   - Direction 내부 루프: 다음 Direction → block
   - Feature 외부 루프: 다음 Feature → block
   - 모두 완료 → 상태 파일 삭제 → allow

---

## 이중 루프: Feature(외부) × Direction(내부)

`/prism design all --directions 3`일 때:

```
Feature 1:
  Direction A → D2(design-md) → DESIGN.md 보존 → D3(새 프로젝트) → D4-D6 → VERIFIED
  Direction B → D2(design-md) → DESIGN.md 보존 → D3(새 프로젝트) → D4-D6 → VERIFIED
  Direction C → D2(design-md) → DESIGN.md 보존 → D3(새 프로젝트) → D4-D6 → VERIFIED
Feature 2:
  Direction A → DESIGN.md 복원 → D3(새 프로젝트, 같은 DESIGN.md) → D4-D6 → VERIFIED
  Direction B → DESIGN.md 복원 → D3(새 프로젝트, 같은 DESIGN.md) → D4-D6 → VERIFIED
  Direction C → DESIGN.md 복원 → D3(새 프로젝트, 같은 DESIGN.md) → D4-D6 → VERIFIED
...
```

**핵심:** 같은 Direction 내의 모든 Feature 프로젝트는 동일한 DESIGN.md를 공유한다.
