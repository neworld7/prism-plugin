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

**Screen State Matrix 6축에 대응하는 코드 패턴을 모두 추출한다.**

> **스택별 참고:** 아래 grep 패턴은 **Flutter** 기준이다. React/Next.js 프로젝트에서는 동일한 축의 의미를 유지하되 패턴을 스택에 맞게 변환한다:
> - Overlays: `showModalBottomSheet` → `Modal|Dialog|Sheet|Drawer` (React 컴포넌트명)
> - Screen States: `CircularProgressIndicator` → `Skeleton|Loading|Spinner` (React 컴포넌트명)
> - Interaction: `_isEditMode` → `isEditing|editMode|useState.*edit` (React hooks 패턴)

> **⚠️ 노이즈 제거:**
> - Flutter: `--glob '!*.g.dart' --glob '!*.freezed.dart'` 또는 `presentation/` 폴더에 한정
> - React/Next.js: `--glob '!node_modules' --glob '!.next' --glob '!dist'` 또는 `src/` 폴더에 한정
> - 공통: 테마/설정 파일, 타입 정의 파일의 false positive 주의

#### 축 1: Primary Screens
```
Flutter: Grep: class.*Screen|class.*Page in lib/
Flutter: Grep: GoRoute|path: in router file (라우트 구조)
React: Grep: export default in src/pages/ or src/views/ (page 컴포넌트)
Next.js: Glob: app/**/page.{tsx,jsx} (파일 기반 라우팅이므로 page 파일 = Primary Screen)
```

#### 축 2: Screen States
```
# 빈 상태 (empty)
Grep: empty.*state|EmptyState|no.*data|아직.*없|등록된.*없|검색.*결과.*없|없어요|없습니다

# 로딩/스켈레톤 (loading/skeleton)
Grep: CircularProgressIndicator|Shimmer|skeleton|isLoading|shimmer

# 에러 (error)
Grep: error.*widget|ErrorWidget|오류|실패|Error.*state|hasError|onError

# 데이터 있음 (populated) — 코드 분석 불필요, 메인 화면이 이 상태
```

#### 축 3: Overlays
```
# 모달/바텀시트
Grep: showModalBottomSheet|showBottomSheet|BottomSheet

# 다이얼로그/확인
Grep: showDialog|AlertDialog|SimpleDialog|삭제.*할까|정말

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
Grep: isSearching|SearchDelegate|showSearch|searchController

# 폼/에디터 (입력 화면 식별용)
Grep: Form\(|_formKey|TextFormField|validator:
```

#### 축 5: System States
```
# 스플래시
Grep: SplashScreen|native_splash|launch_screen|flutter_native_splash

# 권한 요청
Grep: requestPermission|openAppSettings|Permission\.request|getNotificationPermission

# 오프라인/네트워크
Grep: ConnectivityResult|isOffline|noInternet|NetworkException|InternetConnection

# 강제 업데이트
Grep: forceUpdate|RemoteConfig|upgradeRequired|minimumVersion

# 딥링크
Grep: deepLink|universalLink|dynamicLink|getInitialLink
```

#### 축 6: Transitions
```
# 온보딩/투어
Grep: Onboarding|onboarding|tutorial|coach|walkthrough|firstLaunch|isFirst

# 완료/축하
Grep: CompletionScreen|celebration|congrat|축하|완독
```

> **참고:** `onTap`, `onPressed` 등 기본 인터랙션 패턴은 모든 화면에 존재하므로 별도 grep하지 않는다. A2 시뮬레이터 분석에서 인터랙션 특성을 파악한다.

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

### A2: (제거됨)

> A2(시뮬레이터 스크린샷)는 v3.2.0에서 제거되었다. A1 코드 분석만으로 화면/상태/오버레이를 충분히 추출할 수 있고, A4.5 Design Preview에서 새 디자인 방향을 결정하므로 기존 앱 스크린샷 분석이 불필요하다.

### A3: Feature 분리 (심층 — 빠짐없는 화면 도출)

**Goal:** 코드 분석 결과를 바탕으로 Feature 단위로 **모든 화면, 상태 변형, 오버레이, 인터랙션 모드**를 빠짐없이 분류한다. 디자인 완성도가 개발 속도에 직결되므로 화면 수를 제한하지 않는다.

**Steps:**

1. 화면을 기능 단위(Feature)로 그룹화한다. **Feature 분리 기준:**
   - 앱의 **하단 네비게이션 탭** 또는 **주요 섹션**이 자연스러운 Feature 경계
   - 코드 폴더 구조 (`features/auth/`, `features/books/`, `features/stats/`)가 가장 신뢰할 수 있는 기준
   - **Feature는 코드 구조를 존중한다** — 코드에 독립 폴더가 있으면 독립 Feature로 유지
   - **병합 금지**: Feature를 합치지 않는다. 화면이 적은 Feature(예: 스플래시, 설정)도 독립 Feature로 유지
   - **분할 규칙**: Primary Screen 10개 이상이면 사용자 흐름 기준으로 분할
   - Feature 0: Common/System (스플래시, 오프라인, 강제 업데이트 등 공통 화면)

2. 각 Feature의 화면을 **Screen State Matrix**로 분해한다. **모든 축의 모든 항목을 빠짐없이 생성한다:**

**Screen State Matrix — 모바일 앱 화면 분류 체계:**

| 축 | 분류 | 포함 항목 | 필수 여부 |
|---|------|----------|----------|
| **Primary Screens** | 라우트가 있는 독립 화면 | 메인 화면, 상세 화면, 폼/에디터, 설정 하위 화면 | 전부 필수 |
| **Screen States** | 같은 화면의 상태 변형 | `empty`, `loading`/`skeleton`, `error`, `populated`, `disabled` | 전부 필수 — 주요 Primary Screen마다 empty + skeleton + error 3종 생성 |
| **Overlays** | 화면 위에 뜨는 UI | `modal`, `bottom-sheet`, `dialog`, `snackbar/toast`, `tooltip`, `popover`, `drawer`, `action-sheet`, `context-menu` | 코드에서 발견된 것 전부 + 디자인 필수 항목 |
| **Interaction Modes** | 사용자 인터랙션에 의한 모드 전환 | `edit-mode`, `selection-mode`, `drag-reorder`, `swipe-actions`, `long-press-menu`, `keyboard-up`, `search-active`, `filter-panel` | 코드에서 발견된 것 전부 |
| **System States** | 앱/OS 수준 상태 | `splash`, `permission-prompt`, `offline-banner`, `force-update`, `deep-link-landing`, `app-review-prompt` | Feature 0에 전부 배정 |
| **Transitions** | 화면 간 전환/가이드 | `onboarding-tour`, `coach-marks`, `walkthrough`, `completion-celebration`, `first-use-hint` | 해당 Feature에 전부 배정 |

**적용 방법 — 빠짐없는 화면 도출:**
각 Feature의 Primary Screen마다 위 매트릭스의 **모든 축**을 순회하여 필요한 화면을 도출한다. "없어도 될 것 같다"가 아니라 "있어야 하는가"로 판단한다.

```
예시 — "Library" Feature (15개 화면):

Primary Screens (5개):
  1. 서재 (책장, 그리드 뷰)
  2. 서재 (리스트 뷰)
  3. 읽고 있는 책
  4. 책 상세
  5. 책 검색

Screen States (4개):
  6. 서재 (empty — "아직 등록된 책이 없어요")
  7. 서재 (skeleton loading)
  8. 책 검색 (결과 없음 — "검색 결과가 없습니다")
  9. 책 상세 (error — "책 정보를 불러올 수 없습니다")

Overlays (3개):
  10. 정렬/필터 바텀시트
  11. 책 삭제 확인 다이얼로그
  12. 책 추가 방법 선택 바텀시트

Interaction Modes (3개):
  13. 서재 (edit mode + 다중 선택 바)
  14. 서재 (search active + 검색 바)
  15. 책 상세 (읽기 상태 변경 바텀시트)
```

3. **코드에 없더라도 앱에 필수적인 화면은 추가한다:**
   - 주요 Primary Screen마다: `empty`, `skeleton`, `error` 상태 화면 필수 추가
   - 삭제/수정 액션이 있는 화면: 확인 다이얼로그 필수 추가
   - 검색 기능이 있는 화면: `search-active`, `검색 결과 없음` 필수 추가
   - 리스트/그리드 화면: `empty`, `skeleton`, 필터/정렬 오버레이 필수 추가
   - 폼 화면: `keyboard-up` (입력 포커스), 유효성 에러 상태 필수 추가
   - **Feature 배정 규칙**: 특정 Feature에 속하지 않는 공통 화면은 **"0. Common / System"** Feature에 배정

4. **화면 수 목표:**
   - **Feature당 15~20개** 화면 (Primary + States + Overlays + Interaction Modes)
   - **전체 앱 화면 수 제한 없음** — Feature별 독립 Stitch 프로젝트이므로 관리 부담 없음
   - Feature당 화면이 12개 미만이면 Screen State Matrix를 재검토하여 빠진 화면이 없는지 확인
   - Feature당 화면이 25개 이상이면 Feature 분할을 검토

**화면은 삭제하지 않는다.** 모든 화면이 디자인 → 코드 구현에 직접 활용되므로 우선순위에 의한 제거 없음.

5. 각 Feature에 매핑: 포함 화면 목록 (축 태그 포함), 인터랙션, 상태

**Output:** Feature 목록 + Screen State Matrix 기반 화면 목록. 각 화면에 해당 축 태그를 표시한다:

```markdown
## Feature 2: Library (15개)

| # | 화면 | 축 | 소스 |
|---|------|---|------|
| 1 | 서재 (책장, 그리드 뷰) | Primary | 코드 |
| 2 | 서재 (리스트 뷰) | Primary | 코드 |
| 3 | 읽고 있는 책 | Primary | 코드 |
| 4 | 책 상세 | Primary | 코드 |
| 5 | 책 검색 | Primary | 코드 |
| 6 | 서재 (empty) | States: empty | 코드 |
| 7 | 서재 (skeleton) | States: skeleton | 디자인 필수 |
| 8 | 책 검색 (결과 없음) | States: empty | 코드 |
| 9 | 책 상세 (error) | States: error | 디자인 필수 |
| 10 | 정렬/필터 바텀시트 | Overlay: bottom-sheet | 디자인 필수 |
| 11 | 책 삭제 확인 | Overlay: dialog | 코드 |
| 12 | 책 추가 방법 선택 | Overlay: bottom-sheet | 코드 |
| 13 | 서재 (edit mode) | Interaction: edit-mode | 코드 |
| 14 | 서재 (search active) | Interaction: search-active | 코드 |
| 15 | 읽기 상태 변경 | Overlay: bottom-sheet | 코드 |
```

### A4: Feature별 원시 프롬프트 작성

**Goal:** 각 화면에 대해 간결하고 명확한 Stitch 프롬프트를 작성한다.

**Stitch 공식 프롬프팅 원칙:**
1. **Simple → Complex**: 간결하게 시작하고 edit으로 세분화
2. **Vibe로 분위기 설정**: 형용사가 색상, 폰트, 이미지에 영향
3. **한 번에 1-2가지만**: 여러 변경을 한 프롬프트에 넣지 않음
4. **UI/UX 키워드 활용**: navigation bar, card layout, floating action button 등
5. **5000자 이내**: 초과 시 컴포넌트 누락 위험

**프롬프트 구조 (화면당):**

```
{화면 유형} for {앱 이름} — {앱 설명 1줄}.

{바이브 형용사 2-3개로 분위기 설정}

{핵심 UI 요소 나열 — 번호 매긴 고수준 레이아웃}

All UI text must be in Korean (한국어).
Continue using the "{디자인 시스템 이름}" design system.
```

**프롬프트 예시:**

```
Library screen for ReadCodex — a Korean book tracking app.

Warm, editorial, literary atmosphere.

1. Top bar with "책장" title and grid/list toggle
2. Filter tabs: 전체, 읽는 중, 읽고 싶은, 완독
3. 2-column book grid with covers, titles, progress bars
4. Floating action button for adding books
5. Bottom navigation bar

All UI text must be in Korean (한국어).
```

**프롬프트 작성 규칙:**
- ✅ 바이브 형용사로 시작 (warm, minimal, editorial, playful 등)
- ✅ UI/UX 키워드 사용 (navigation bar, card layout, hero section, floating action button)
- ✅ 요소를 구체적으로 참조 (primary button, search bar in header, image in hero section)
- ✅ 화면당 100-300자 — 간결하게
- ❌ hex 코드, px 값, 특정 폰트명 금지
- ❌ 5000자 초과 프롬프트 금지 (컴포넌트 누락 위험)
- ❌ 한 프롬프트에 3개 이상 변경 사항 금지
- ✅ 프롬프트는 영어, 마지막에: `All UI text must be in Korean (한국어).`

**Output:** Feature별 간결한 프롬프트 (Feature당 15~20개). 디자인 시스템 토큰은 미포함.

### A4.5: Design Preview — 7개 시안 생성

**Goal:** 핵심 화면 4-5개로 7가지 디자인 방향을 시각적으로 미리보기한다. 모두 LIGHT 모드. 사용자가 선호하는 디자인을 선택하면 해당 디자인 시스템으로 전체 앱을 생성한다. (다크 모드는 별도 진행)

**핵심 화면 선정 기준:**
- 디자인 요소가 풍부한 Feature에서 선정 (리스트, 카드, 차트, 상세 화면 등)
- 로그인, 온보딩, 스플래시 등 디자인 차별화가 어려운 화면은 제외
- 앱의 핵심 사용자 흐름을 대표하는 화면 우선 (예: 서재, 책 상세, 통계 대시보드)
- A3의 Feature 목록에서 Primary Screen이 가장 많고 다양한 Feature에서 4-5개 선정

**3축 프레임워크 (방향 다양성 보장):**

| 축 | 역할 | 예시 값 |
|---|---|---|
| **아키타입** | 전체 디자인 느낌 | Editorial Elegance, Scandinavian Clean, Playful Pastel, Japanese Zen, Warm Organic, Glassmorphism, Neo-Brutalist |
| **레이아웃** | 화면 구조/창의적 배치 | Centered Stack, Split Screen, Bottom Sheet, Full-bleed Hero, Card-based, Magazine Grid, Asymmetric |
| **레퍼런스 앱** | 참조 디자인 DNA | Notion, Linear, Duolingo, 밀리의서재, Spotify, Airbnb, Apple Books |

**7개 시안 다양성 보장 규칙:**

모든 시안은 **LIGHT 모드 고정**. 차별화는 느낌, 레이아웃, 창의적 구조로 한다.
시안은 아래 7가지 디자인 스펙트럼을 **각각 1개씩** 커버해야 한다:

| # | 스펙트럼 | 아키타입 예시 | 차별화 포인트 |
|---|---------|------------|-------------|
| 1 | 따뜻한/감성적 | Warm Organic, Cozy Editorial | Serif 서체, 크림/브라운 톤, 둥근 모서리, 종이 질감 |
| 2 | 차분한/미니멀 | Japanese Zen, Scandinavian Clean | 넓은 여백, 모노톤, 절제된 색상, 직선 구조 |
| 3 | 세련된/프리미엄 | Editorial Elegance, Swiss Design | 고급 타이포, 절제된 골드/네이비, 매거진 레이아웃 |
| 4 | 밝은/모던 | Flat Modern, Material You | 체계적 그리드, 산세리프, 컬러풀 악센트, 카드 기반 |
| 5 | 친근한/유쾌 | Playful Pastel, Rounded Friendly | 파스텔 톤, 큰 둥근 모서리, 일러스트 강조, 부드러운 그림자 |
| 6 | 대담한/표현적 | Glassmorphism, Neo-Brutalist | 비대칭 레이아웃, 블러 효과 또는 강한 타이포, 실험적 구조 |
| 7 | 자연적/유기적 | Earthy Natural, Botanical | 자연 색상(그린/테라코타), 유기적 곡선, 텍스처 배경, 핸드메이드 느낌 |

**금지 규칙:**
- colorMode는 **전부 LIGHT** 고정 (다크 모드는 별도 진행)
- 같은 font family가 3개 이상이면 안 됨
- 같은 레퍼런스 앱을 2개 이상 사용하면 안 됨
- 7개 아키타입이 위 스펙트럼의 서로 다른 행에서 와야 함

**앱 맥락 반영:**
- 앱의 타겟 사용자와 도메인에 맞지 않는 극단적 방향은 제외
- 대신 해당 스펙트럼 위치에서 앱에 맞는 변형을 선택

**실행:**
```
1. 핵심 화면 4-5개 선정 → 사용자 확인
2. 7개 Direction 시안 정의 (3축 기반, 7개 스펙트럼 각 1개)
3. Direction별 Stitch 프로젝트 생성:
   → 프로젝트 이름: "{App} — Preview — {Direction 이름}"
   → 예시: "ReadCodex — Preview — Warm Organic"
4. 각 프로젝트에 핵심 화면 4-5개 생성 (배치 호출 1회)
5. 총 7개 프로젝트 × 4-5개 화면 = 약 35개 화면
6. get_project로 각 프로젝트의 스크린샷 다운로드
7. 사용자에게 7개 Direction 비교 제시 → 1개 선택
8. 선택된 Direction의 get_project → designTheme 추출
9. ./DESIGN.md 저장 (프로젝트 최상위, 이름 + 메타데이터 + designMd 전문)
10. .prism/preview/ 에 프로젝트 ID 기록
```

**출력 형식:**
```
📐 Direction 1: "{Direction 이름}"
  아키타입: {아키타입} — {핵심 특성 1줄}
  레이아웃: {레이아웃} — {구조 설명 1줄}
  레퍼런스: {레퍼런스 앱} — {해당 앱의 어떤 측면을 참조하는지}
  프로젝트: {Stitch URL}
  스크린샷: 4-5개 화면 썸네일

📐 Direction 2: ...
...
📐 Direction 7: ...

→ 위 7개 Direction 중 1개를 선택해주세요.
```

**사용자 응답 처리:**
- "3" → 선택된 Direction 확정, A6으로 진행
- "3번을 X로 바꿔주세요" → 해당 프로젝트 재생성 후 재표시
- 전체 재생성 요청 → A4.5 처음부터 재실행

### A5: 프롬프트 최적화 — 공식 스킬 위임

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

```
Skill("enhance-prompt") 호출 1회
→ A4에서 작성한 원시 프롬프트를 전달
→ DESIGN.md 경로 전달 안 함 (디자인 토큰은 Stitch가 D3에서 자체 결정)
→ 결과를 .prism/prompts.md에 저장
```

### A6: 산출물 저장

**Goal:** 분석 결과를 저장하고 사용자 확인을 받는다.

**파일 구조:**

```
./DESIGN.md                      ← A4.5에서 선택된 Direction의 designTheme (프로젝트 최상위)
.prism/
  analysis.md                    ← 공통 (A1-A4 산출물)
  prompts.md                     ← A5 결과
  preview/                       ← A4.5 시안 프로젝트
    project-ids.md               ← 5개 시안 프로젝트 ID
  project-ids.md                 ← D3 생성 프로젝트 ID
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

| # | 화면 | 축 태그 | 소스 | 코드 파일 |
|---|------|--------|------|-----------|
| 1 | 로그인 | Primary | 코드 발견 | login_screen.dart |
```

**prompts.md 템플릿:**

```markdown
# {App} Prompts

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

### Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 건너뛴다.

1. Read `.claude/prism-design-pipeline.local.md` → `feature` 필드 확인
2. `.prism/prompts.md`에서 해당 Feature 프롬프트만 추출

### D1: prompts.md 로드

**Goal:** 프롬프트를 로드한다.

**Steps:**
1. `.prism/prompts.md` 존재 확인
2. 없으면 `/prism analyze` 먼저 실행 안내
3. 있으면 해당 Feature의 프롬프트 로드

### D2: (제거됨 — Phase 번호 호환성을 위해 유지)

> D2는 v2.10.0에서 제거되었다. Stitch가 첫 화면 생성 시 디자인 시스템을 자동 생성하므로 외부 DESIGN.md 생성이 불필요하다.
> 디자인 시스템 일관성은 D3의 "Design System Name Anchor" 패턴으로 보장한다.
> 기존 D3-D6 번호를 유지한다.

### D3: 디자인 생성 — Feature별 프로젝트

**Goal:** Feature 프롬프트로 Stitch 디자인을 생성한다.

**Design Identity 판단 (D3 시작 시):**

`./DESIGN.md` 존재 여부로 분기:

**미존재 (첫 Feature):**
```
1. create_project → 첫 화면 generate_screen_from_text
2. get_project → designTheme에서 추출:
   - 이름: designTheme.designMd 첫 # 헤딩 파싱 또는 outputComponents 텍스트
   - designMd 전문: designTheme.designMd (전체 디자인 시스템 스펙)
   - 메타데이터: colorMode, roundness, font, headlineFont, bodyFont
   - Fallback: designMd 미생성 → 2번째 화면 후 get_project 재시도 / 2회 실패 → 앵커 없이 진행
3. DESIGN.md 저장 (프로젝트 최상위):
   | 항목 | 값 |
   |------|------|
   | Name | {추출된 이름} |
   | Source Project | projects/{projectId} |
   | Color Mode | {designTheme.colorMode} |
   | Roundness | {designTheme.roundness} |
   | Primary Font | {designTheme.font 또는 headlineFont} |
   | Body Font | {designTheme.bodyFont} |
   + "## Design System Spec" 섹션에 designMd 전문 포함
4. 나머지 화면 생성 시 프롬프트 끝에 앵커 삽입:
   Continue using the "{Name}" design system established in this project.
```

**존재 (이후 Feature):**
```
1. enhance-prompt 스킬이 ./DESIGN.md를 자동으로 읽어서 프롬프트에 디자인 시스템 토큰을 주입한다. 수동 삽입 불필요.
2. create_project → generate_screen_from_text (전체 화면 순차)
3. 나머지 화면 프롬프트 끝에 간결한 앵커 삽입:
   Continue using the "{Name}" design system established in this project.
```

> **핵심:** 이후 Feature에서는 enhance-prompt 스킬이 ./DESIGN.md를 자동 주입하므로 수동 삽입이 불필요하다. 나머지 화면은 프로젝트 내부 일관성에 의존한다.

**⚠️ 프로젝트 구조: Feature별 프로젝트 분리**

```
Feature별로 별도 Stitch 프로젝트를 생성한다:
→ 프로젝트 이름: "{App} — {Feature번호}. {Feature명}"
→ 예시: "ReadCodex — 1. Auth & Onboarding"
→ 예시: "ReadCodex — 2. Library"
→ 각 프로젝트에 해당 Feature의 모든 화면 (메인 + 서브 + 모달 + 상태)을 생성
→ 생성된 프로젝트 ID를 .prism/project-ids.md에 기록:
   | Feature | Project ID | Stitch URL |
   |---------|-----------|------------|
   | 1. Auth | 1234567890 | https://stitch.withgoogle.com/projects/1234567890 |
```

**실행 — 축 단위 배치 생성:**
```
1. create_project 호출 → 프로젝트 생성 (프로젝트 이름에 Feature 포함)
2. 해당 Feature의 화면을 축(Axis) 단위로 묶어서 배치 생성:
   - 1차 호출: Primary Screens (5-7개) — 핵심 화면 전체
   - 2차 호출: Screen States (3-5개) — empty, skeleton, error 상태
   - 3차 호출: Overlays (3-4개) — 바텀시트, 다이얼로그, 액션시트
   - 4차 호출: Interaction Modes (2-4개) — edit, search, filter 모드
3. 각 호출: generate_screen_from_text 1회 (해당 축의 화면을 간결하게 기술)
4. 생성 확인 후 다음 축으로
```

**배치 프롬프트 구조 (Stitch 공식 가이드 준수):**

각 화면을 간결하게 기술하고, 바이브 형용사와 UI/UX 키워드를 활용한다.
5000자 이내를 반드시 준수한다.

```
Design {N} {축 이름} screens for the {Feature} feature of {App} — {앱 설명 1줄}.

{바이브 형용사 2-3개}. {디자인 시스템 앵커}.

**Screen 1: {화면명}**
{간결한 설명 — 핵심 UI 요소만, 100-200자}

**Screen 2: {화면명}**
{간결한 설명}

...

All UI text must be in Korean (한국어).
```

**배치 프롬프트 예시:**

```
Design 5 primary screens for the Library feature of ReadCodex — a Korean book tracking app.

Warm, editorial, literary atmosphere. Continue using the "The Scholarly Editorial" design system.

**Screen 1: 서재 (책장, 그리드 뷰)**
Book grid with 2-column layout, cover images, titles, reading progress bars. Top filter tabs, floating add button, bottom navigation.

**Screen 2: 서재 (리스트 뷰)**
List view with book covers, titles, authors, progress percentage. Same top bar and navigation as grid view.

**Screen 3: 읽고 있는 책**
Currently reading carousel with large cover, progress ring, "이어 읽기" CTA button. Daily reading streak card below.

**Screen 4: 책 상세**
Book detail with hero cover image, title in serif, author, genre chips. Reading timeline, action buttons for resume and notes.

**Screen 5: 책 검색**
Search bar with recent searches and autocomplete. Results as compact book cards with cover, title, author.

All UI text must be in Korean (한국어).
```

**모델 강제 규칙:**
`generate_screen_from_text` 호출 시 반드시 `modelId: "GEMINI_3_1_PRO"`를 명시한다.

**⚠️ Stitch API 배치 생성 규칙 (필수):**

Stitch `generate_screen_from_text`는 비동기적으로 동작한다. 배치 생성 시 다음 규칙을 반드시 지킨다:

1. **"no output" 응답 ≠ 실패** — API가 `(completed with no output)`을 반환해도 화면이 생성되었을 수 있다. **절대 즉시 재시도하지 않는다.**

2. **생성 확인은 `get_project`로** — `list_screens`는 빈 결과를 반환할 수 있으므로 사용하지 않는다. 대신 `get_project`의 `screenInstances` 배열에서 실제 화면 수를 확인한다.

3. **배치 생성 후 확인 절차:**
   ```
   generate_screen_from_text 호출 (1회, N개 화면 기술)
   ↓
   outputComponents 있으면 → 성공, 생성된 화면 수 확인
   outputComponents 없으면 ("no output") → 15초 간격 폴링 시작 (최대 120초)
   ↓
   매 15초마다 get_project → screenInstances 배열 확인
   ↓
   N개 이상 증가 감지 → 즉시 성공 처리
   120초까지 미증가 → 축을 2분할하여 재시도 (예: 5개 → 3개 + 2개)
   ```

4. **재시도 전 중복 체크** — `screenInstances`에 이미 존재하는 화면은 재생성하지 않는다.

5. **화면 수 기록** — 각 배치 호출 전에 `get_project`로 현재 `screenInstances.length`를 기록해두어 생성 후 비교한다.

6. **배치 실패 시 분할 전략** — N개 배치가 실패하면 축을 2분할:
   - 5개 → 3개 + 2개
   - 7개 → 4개 + 3개
   - 분할 후에도 실패 → 1개씩 개별 생성으로 폴백

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

**Stitch 공식 수정 원칙:**
- **한 번에 1-2가지만 수정** — 여러 변경을 한 프롬프트에 넣지 않음
- **what + how 명시** — 무엇을 어떻게 바꿀지 구체적으로
- **요소를 구체적으로 참조** — "primary button on sign-up form", "image in hero section"
- 수정이 예상과 다르면 **표현을 바꿔서 재시도**

**수정 프롬프트 구조:**
```
On {화면명}, {what을 how로 변경}.
```

**수정 프롬프트 예시:**
```
"On the library screen, make the book grid 3 columns instead of 2."
"On the book detail page, add a horizontal scroll of related books at the bottom."
"Change the floating action button color to match the primary accent."
```

```
Skill("stitch-design") 호출
→ 수정 프롬프트 전달 (1-2가지 변경만)
→ 수정 결과 확인 → 예상과 다르면 표현 바꿔서 재시도
```
**Transition:** D4로 복귀.

### D6: 완료

1. `<promise>DESIGN_VERIFIED</promise>` 출력
2. Stop hook이 감지:
   - 다음 Feature → block
   - 모든 Feature 완료 → 상태 파일 삭제 → allow

---

## Feature 루프

`/prism design all`일 때:

```
Feature 1 → ./DESIGN.md에서 designMd 추출 → D3(배치 생성) → D4-D6 → VERIFIED
Feature 2 → ./DESIGN.md에서 designMd 추출 → D3(배치 생성) → D4-D6 → VERIFIED
Feature 3 → ./DESIGN.md에서 designMd 추출 → D3(배치 생성) → D4-D6 → VERIFIED
...
```

**핵심:** 모든 Feature 프로젝트는 A4.5에서 선택된 동일한 디자인 시스템(./DESIGN.md)을 공유한다.
