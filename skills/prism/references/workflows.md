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

**Screen State Matrix 7축에 대응하는 코드 패턴을 모두 추출한다.**

> **7축 설계 근거:** Scott Hurff UI Stack(Partial 상태), Apple HIG 2026(접근성 격상), Material Design 3(컴포넌트 상태)을 종합하여 기존 6축에서 Transitions를 App Lifecycle에 병합하고, Auth & Entitlement/Environment Variants를 추가한 7축 구조.

> **스택별 참고:** 아래 grep 패턴은 **Flutter** 기준이다. React/Next.js 프로젝트에서는 동일한 축의 의미를 유지하되 패턴을 스택에 맞게 변환한다:
> - Overlays: `showModalBottomSheet` → `Modal|Dialog|Sheet|Drawer` (React 컴포넌트명)
> - Data States: `CircularProgressIndicator` → `Skeleton|Loading|Spinner` (React 컴포넌트명)
> - Interaction: `_isEditMode` → `isEditing|editMode|useState.*edit` (React hooks 패턴)
> - Auth: `currentUser` → `useAuth|useSession|isAuthenticated` (React hooks 패턴)

> **⚠️ 노이즈 제거:**
> - Flutter: `--glob '!*.g.dart' --glob '!*.freezed.dart'` 또는 `presentation/` 폴더에 한정
> - React/Next.js: `--glob '!node_modules' --glob '!.next' --glob '!dist'` 또는 `src/` 폴더에 한정
> - 공통: 테마/설정 파일, 타입 정의 파일의 false positive 주의

> **실용적 적용:** 모든 축을 교차하면 조합 폭발이 발생한다. **Primary Screens × Data States**를 필수 매트릭스로, 나머지 5축은 해당 화면에 관련된 항목만 선택적으로 표기한다.

#### 축 1: Primary Screens
```
Flutter: Grep: class.*Screen|class.*Page in lib/
Flutter: Grep: GoRoute|path: in router file (라우트 구조)
React: Grep: export default in src/pages/ or src/views/ (page 컴포넌트)
Next.js: Glob: app/**/page.{tsx,jsx} (파일 기반 라우팅이므로 page 파일 = Primary Screen)
```

#### 축 2: Data States (구 Screen States — Partial 추가)
```
# 빈 상태 (empty)
Grep: empty.*state|EmptyState|no.*data|아직.*없|등록된.*없|검색.*결과.*없|없어요|없습니다

# 부분 데이터 (partial — 데이터가 1-2개뿐인 어색한 상태)
Grep: (코드에서 직접 감지 어려움 — Primary Screen별 "데이터 1-2건일 때" 변형을 디자인 필수로 추가)

# 로딩/스켈레톤 (loading/skeleton)
Grep: CircularProgressIndicator|Shimmer|skeleton|isLoading|shimmer

# 에러 (error)
Grep: error.*widget|ErrorWidget|오류|실패|Error.*state|hasError|onError

# 데이터 있음 (populated) — 코드 분석 불필요, 메인 화면이 이 상태

# 비활성 (disabled)
Grep: isDisabled|isEnabled.*false|AbsorbPointer|IgnorePointer
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

# 키보드 표시 (키보드에 의한 레이아웃 변화)
Grep: MediaQuery.*viewInsets|keyboardHeight|SingleChildScrollView.*Form|resizeToAvoidBottomInset
```

#### 축 5: App Lifecycle (구 System States + Transitions 병합)
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

# 온보딩/투어 (구 축6 Transitions에서 병합)
Grep: Onboarding|onboarding|tutorial|coach|walkthrough|firstLaunch|isFirst

# 완료/축하 (구 축6 Transitions에서 병합)
Grep: CompletionScreen|celebration|congrat|축하|완독
```

#### 축 6: Auth & Entitlement (신규)
```
# 로그인/비로그인 분기
Grep: isLoggedIn|currentUser|isAuthenticated|authState|signedIn

# 구독/프리미엄 분기
Grep: isPremium|isSubscribed|subscription|freeTier|paywall|entitlement

# 역할 분기 (관리자/일반)
Grep: isAdmin|isOwner|isMember|role.*admin|canEdit|canDelete|permission

# 본인/타인 프로필 분기
Grep: isOwnProfile|isCurrentUser|isMine|userId.*==.*currentUser
```

> **Auth 축 적용 방법:** 같은 화면이 auth 상태에 따라 완전히 달라지는 경우(예: 비로그인 홈 vs 로그인 홈, 무료 vs 프리미엄 기능)만 별도 화면으로 생성한다. 단순한 버튼 숨김/표시 정도는 별도 화면 불필요.

#### 축 7: Environment Variants (신규)
```
# 화면 크기 분기 (태블릿/폴더블)
Grep: MediaQuery.*size|LayoutBuilder|Breakpoint|isTablet|isFoldable|AdaptiveLayout

# 플랫폼 분기 (iOS/Android)
Grep: Platform\.isIOS|Platform\.isAndroid|CupertinoSwitch|adaptive.*widget|\.adaptive

# 접근성 모드
Grep: Semantics|ExcludeSemantics|SemanticsLabel|AccessibilityFeatures|textScaleFactor|boldText

# 동기화 상태 (오프라인 데이터)
Grep: syncStatus|isSyncing|syncConflict|staleData|lastSynced|pendingSync
```

> **Environment 축 적용 방법:** 디자인 시안에서는 기본 환경(phone, primary platform, 기본 접근성)으로 생성하되, 이 축의 항목을 **체크리스트**로 관리하여 구현 시 대응 여부를 확인한다. 태블릿 레이아웃이 코드에 이미 구현된 경우에만 별도 화면을 생성한다.

> **참고:** `onTap`, `onPressed` 등 기본 인터랙션 패턴은 모든 화면에 존재하므로 별도 grep하지 않는다.

**각 축에서 발견된 코드 위치를 아래 형식으로 정리**하여 A3의 입력 데이터로 사용한다.

**Output 형식 (A1 → A3 전달 구조):**

```markdown
## A1 코드 분석 결과

### 축 1: Primary Screens (N개)
| # | 화면 클래스 | 파일 경로 | 라우트 |
|---|-----------|----------|-------|
| 1 | LoginScreen | auth/login_screen.dart | /login |

### 축 2: Data States (N개)
| # | 상태 유형 | 발견 위치 | 관련 화면 |
|---|---------|----------|----------|
| 1 | empty | home_screen.dart:120 "아직 항목이 없습니다" | 홈 |
| 2 | partial | (디자인 필수 — 데이터 1-2건만 있을 때) | 홈 |

### 축 3: Overlays (N개)
| # | 오버레이 유형 | 발견 위치 | 관련 화면 | 용도 |
|---|------------|----------|----------|------|
| 1 | bottom-sheet | detail_screen.dart:397 showModalBottomSheet | 상세 | 상태 변경 |

### 축 4: Interaction Modes (N개)
| # | 모드 | 발견 위치 | 관련 화면 |
|---|-----|----------|----------|
| 1 | edit-mode | list_screen.dart:36 _isEditMode | 리스트 |
| 2 | keyboard-visible | editor_screen.dart:42 Form | 에디터 |

### 축 5: App Lifecycle (N개)
| # | 상태 | 발견 위치 |
|---|-----|----------|
| 1 | permission | notification_service.dart getToken |
| 2 | onboarding | onboarding_screen.dart |
| 3 | completion | completion_screen.dart |

### 축 6: Auth & Entitlement (N개)
| # | 분기 유형 | 발견 위치 | 관련 화면 |
|---|---------|----------|----------|
| 1 | premium | premium_feature_screen.dart:58 isPremium | 프리미엄 기능 |

### 축 7: Environment Variants (N개)
| # | 변형 유형 | 발견 위치 |
|---|-----|----------|
| 1 | tablet | home_screen.dart:25 LayoutBuilder | 홈 |
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

**Screen State Matrix — 모바일 앱 화면 분류 체계 (7축):**

> 근거: Scott Hurff UI Stack + Apple HIG 2026 + Material Design 3

| 축 | 분류 | 포함 항목 | 필수 여부 |
|---|------|----------|----------|
| **Primary Screens** | 라우트가 있는 독립 화면 | 메인 화면, 상세 화면, 폼/에디터, 설정 하위 화면 | 전부 필수 |
| **Data States** | 같은 화면의 데이터 상태 변형 | `empty`, `partial`, `loading`/`skeleton`, `error`, `populated`, `disabled` | 전부 필수 — 주요 Primary Screen마다 empty + partial + skeleton + error 4종 생성 |
| **Overlays** | 화면 위에 뜨는 UI | `modal`, `bottom-sheet`, `dialog`, `snackbar/toast`, `tooltip`, `popover`, `drawer`, `action-sheet`, `context-menu` | 코드에서 발견된 것 전부 + 디자인 필수 항목 |
| **Interaction Modes** | 사용자 인터랙션에 의한 모드 전환 | `edit-mode`, `selection-mode`, `drag-reorder`, `swipe-actions`, `long-press-menu`, `keyboard-visible`, `search-active`, `filter-panel` | 코드에서 발견된 것 전부 |
| **App Lifecycle** | 앱 생애주기 상태 (구 System States + Transitions 병합) | `splash`, `permission-prompt`, `offline-banner`, `force-update`, `deep-link-landing`, `onboarding-tour`, `coach-marks`, `completion-celebration` | Feature 0에 전부 배정 |
| **Auth & Entitlement** | 인증/권한에 따른 화면 분기 | `logged-out`, `logged-in`, `guest`, `free-tier`, `premium`, `admin`, `own-profile`, `other-profile` | 같은 화면이 auth 상태에 따라 **완전히 달라지는** 경우만 별도 화면 생성 |
| **Environment Variants** | 환경에 따른 화면 변형 | `phone`/`tablet`/`foldable`, `iOS`/`Android`, `accessibility`(VoiceOver, large-text, high-contrast), `offline-sync` | 체크리스트로 관리 — 코드에 이미 구현된 변형만 별도 화면 생성 |

**적용 방법 — 빠짐없는 화면 도출:**
각 Feature의 Primary Screen마다 위 매트릭스의 **모든 축**을 순회하여 필요한 화면을 도출한다. "없어도 될 것 같다"가 아니라 "있어야 하는가"로 판단한다.

```
예시 A — "Products" Feature (커머스 앱, 17개 화면):

Primary Screens (5개):
  1. 상품 목록 (그리드 뷰)
  2. 상품 목록 (리스트 뷰)
  3. 상품 상세
  4. 상품 검색
  5. 카테고리 필터

Data States (5개):
  6. 상품 목록 (empty — "등록된 상품이 없습니다")
  7. 상품 목록 (partial — 상품 1-2개만 있을 때)
  8. 상품 목록 (skeleton loading)
  9. 상품 검색 (결과 없음 — "검색 결과가 없습니다")
  10. 상품 상세 (error — "상품 정보를 불러올 수 없습니다")

Overlays (3개):
  11. 정렬/필터 바텀시트
  12. 상품 삭제 확인 다이얼로그
  13. 장바구니 담기 성공 스낵바

Interaction Modes (3개):
  14. 상품 목록 (edit mode + 다중 선택)
  15. 상품 목록 (search active + 검색 바)
  16. 상품 상세 (옵션 선택 바텀시트)

Auth & Entitlement (1개):
  17. 상품 목록 (비로그인 — "로그인하고 찜하기를 이용해보세요")

예시 B — "Dashboard" Feature (피트니스 앱, 16개 화면):

Primary Screens (4개):
  1. 오늘 대시보드 (운동 요약 + 칼로리)
  2. 운동 기록 상세
  3. 주간/월간 통계
  4. 목표 설정

Data States (5개):
  5. 대시보드 (empty — "첫 운동을 시작해보세요")
  6. 대시보드 (partial — 오늘 데이터만 있을 때)
  7. 대시보드 (skeleton loading)
  8. 통계 (error — "데이터를 불러올 수 없습니다")
  9. 운동 기록 (empty — "이 기간에 기록이 없습니다")

Overlays (3개):
  10. 운동 종류 선택 바텀시트
  11. 기록 삭제 확인 다이얼로그
  12. 목표 달성 축하 다이얼로그

Interaction Modes (2개):
  13. 통계 (기간 선택 필터 패널)
  14. 대시보드 (위젯 편집/드래그 모드)

Auth & Entitlement (2개):
  15. 통계 (무료 — 기본 차트만, 프리미엄 잠금 표시)
  16. 대시보드 (비로그인 — "로그인하고 운동을 기록하세요")
```

> **참고:** 위 예시는 도메인별 참고용이다. 실제 화면 목록은 A1 코드 분석 결과에서 자동 도출된다.

3. **코드에 없더라도 앱에 필수적인 화면은 추가한다:**
   - 주요 Primary Screen마다: `empty`, `partial`, `skeleton`, `error` 상태 화면 필수 추가
   - 삭제/수정 액션이 있는 화면: 확인 다이얼로그 필수 추가
   - 검색 기능이 있는 화면: `search-active`, `검색 결과 없음` 필수 추가
   - 리스트/그리드 화면: `empty`, `partial`, `skeleton`, 필터/정렬 오버레이 필수 추가
   - 폼 화면: `keyboard-visible` (입력 포커스), 유효성 에러 상태 필수 추가
   - 인증 분기가 있는 화면: 비로그인/무료/프리미엄 변형 중 UI가 크게 달라지는 것만 추가
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
## Feature 2: {Feature명} ({N}개)

| # | 화면 | 축 | 소스 |
|---|------|---|------|
| 1 | 메인 목록 (그리드 뷰) | Primary | 코드 |
| 2 | 메인 목록 (리스트 뷰) | Primary | 코드 |
| 3 | 상세 | Primary | 코드 |
| 4 | 검색 | Primary | 코드 |
| 5 | 메인 목록 (empty) | Data: empty | 코드 |
| 6 | 메인 목록 (partial) | Data: partial | 디자인 필수 |
| 7 | 메인 목록 (skeleton) | Data: skeleton | 디자인 필수 |
| 8 | 검색 (결과 없음) | Data: empty | 코드 |
| 9 | 상세 (error) | Data: error | 디자인 필수 |
| 10 | 정렬/필터 바텀시트 | Overlay: bottom-sheet | 디자인 필수 |
| 11 | 삭제 확인 | Overlay: dialog | 코드 |
| 12 | 추가 방법 선택 | Overlay: bottom-sheet | 코드 |
| 13 | 메인 목록 (edit mode) | Interaction: edit-mode | 코드 |
| 14 | 메인 목록 (search active) | Interaction: search-active | 코드 |
| 15 | 메인 목록 (비로그인) | Auth: logged-out | 코드 |
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

**프롬프트 예시 (도메인별):**

```
예시 A — 커머스 앱:
Product list screen for FreshCart — a grocery delivery app.

Clean, modern, appetizing atmosphere.

1. Top bar with "상품" title and grid/list toggle
2. Category chips: 전체, 과일, 채소, 유제품, 음료
3. 2-column product grid with images, names, prices, add-to-cart buttons
4. Floating cart button with item count badge
5. Bottom navigation bar

All UI text must be in Korean (한국어).
```

```
예시 B — 피트니스 앱:
Dashboard screen for FitLog — a workout tracking app.

Energetic, bold, motivating atmosphere.

1. Top bar with greeting and streak counter
2. Today's summary card with calories, steps, active minutes
3. Recent workout list with type icons and duration
4. Circular progress ring for daily goal
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

**Goal:** 핵심 화면 10개로 7가지 디자인 방향을 시각적으로 미리보기한다. 모두 LIGHT 모드. 사용자가 선호하는 디자인을 선택하면 해당 디자인 시스템으로 전체 앱을 생성한다. (다크 모드는 별도 진행)

**핵심 화면 선정 기준:**
- 디자인 요소가 풍부한 Feature에서 선정 (리스트, 카드, 차트, 상세 화면 등)
- 로그인, 온보딩, 스플래시 등 디자인 차별화가 어려운 화면은 제외
- 앱의 핵심 사용자 흐름을 대표하는 화면 우선 (예: 홈/대시보드, 상세, 목록, 프로필)
- A3의 Feature 목록에서 Primary Screen이 가장 많고 다양한 Feature에서 10개 선정

**3축 프레임워크 (방향 다양성 보장):**

| 축 | 역할 | 예시 값 |
|---|---|---|
| **아키타입** | 전체 디자인 느낌 | Editorial Elegance, Scandinavian Clean, Playful Pastel, Japanese Zen, Warm Organic, Glassmorphism, Neo-Brutalist |
| **레이아웃** | 화면 구조/창의적 배치 | Centered Stack, Split Screen, Bottom Sheet, Full-bleed Hero, Card-based, Magazine Grid, Asymmetric |
| **레퍼런스 앱** | 참조 디자인 DNA | Notion, Linear, Duolingo, Spotify, Airbnb, Nike Run Club, Strava, Headspace |

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

**시장 리서치 (시안 정의 전 필수):**

시안을 기계적으로 배정하지 않고, 앱 도메인에 맞는 디자인 트렌드를 리서치하여 근거 있는 제안을 한다.

```
1. 앱 컨텍스트 파악:
   - analysis.md에서 앱 목적, 타겟 사용자, 도메인 추출
   - 예: "식료품 배달 앱, 2030 1인 가구 대상" 또는 "피트니스 트래킹 앱, 운동 초보자 대상"

2. WebSearch로 시장 리서치:
   - "{도메인} app UI design trends 2026" 검색
   - "{도메인} best app design examples" 검색
   - 경쟁 앱 3-5개의 디자인 특징 요약
   - 현재 UI/UX 트렌드 (해당 도메인 특화) 파악

3. 리서치 결과 + 7가지 스펙트럼을 결합하여 시안 정의:
   - 안정 60%: 시장에서 검증된 패턴 반영
   - 창의 40%: 차별화된 요소로 독창성 확보
   - 각 시안에 구체적 레퍼런스 앱 + 참조 근거 명시
```

**실행:**
```
1. 시장 리서치 수행 (위 절차)
2. 핵심 화면 10개 선정 → 사용자 확인
3. 리서치 기반 7개 Direction 시안 정의 (스펙트럼 × 리서치 결합)
4. Direction별 Stitch 프로젝트 생성:
   → 프로젝트 이름: "{App} · Preview · {Direction 이름}"
   → 예시: "{App} · Preview · Warm Organic"
5. 각 프로젝트에 핵심 화면 10개 생성 (배치 호출 1회)
6. 총 7개 프로젝트 × 10개 화면 = 약 70개 화면
7. get_project로 각 프로젝트의 스크린샷 다운로드
8. 사용자에게 7개 Direction 비교 제시
9. "저장할 시안을 선택하세요 (예: 1, 3, 5)" → 선택된 시안만 저장:
   - .prism/preview/{direction-name}/DESIGN.md ← designTheme.designMd
   - .prism/preview/{direction-name}/screenshots/ ← 화면 스크린샷
10. "활성 시안을 선택하세요 (예: 3)" → 해당 시안의 DESIGN.md를 ./DESIGN.md로 복사
11. .prism/preview/index.md에 프로젝트 ID 기록
```

**출력 형식:**

먼저 리서치 결과를 공유한 후 시안을 제시한다:
```
🔍 시장 리서치 결과:
  도메인: {앱 도메인}
  타겟: {타겟 사용자}
  트렌드: {현재 해당 도메인 디자인 트렌드 2-3줄}
  경쟁앱:
    - {앱1}: {디자인 특징}
    - {앱2}: {디자인 특징}
    - {앱3}: {디자인 특징}

📐 Direction 1: "{Direction 이름}"
  아키타입: {아키타입} — {핵심 특성 1줄}
  레이아웃: {레이아웃} — {구조 설명 1줄}
  레퍼런스: {레퍼런스 앱} — {해당 앱의 어떤 측면을 참조하는지}
  근거: 안정({검증된 패턴}) + 창의({차별화 포인트})
  프로젝트: {Stitch URL}
  스크린샷: 10개 화면 썸네일

📐 Direction 2: ...
...
📐 Direction 7: ...

→ 저장할 시안을 선택하세요 (예: "1, 3, 5")
→ 활성 시안을 선택하세요 (예: "3")
```

**사용자 응답 처리:**
- "1, 3, 5 저장 / 3 활성" → 3개 저장, 3번을 ./DESIGN.md로 복사, A6으로 진행
- "3번을 X로 바꿔주세요" → 해당 프로젝트 재생성 후 재표시
- 전체 재생성 요청 → A4.5 처음부터 재실행
- 나중에 전환: `/prism preview use {name}` → 저장된 시안을 ./DESIGN.md로 교체

**`/prism preview add` — 시안 추가:**

| 입력 방식 | 사용법 | 동작 |
|-----------|--------|------|
| AI 제안 | `/prism preview add` | 시장 리서치 + 기존 시안 분석 → 새 방향 제안 |
| 텍스트 | `/prism preview add 네이버 블로그 느낌으로` | 사용자 설명 기반 시안 정의 → 생성 |
| 이미지 | `/prism preview add` + 이미지 첨부 | 이미지 분석 (색상, 레이아웃, 분위기) → 시안 정의 → 생성 |

```
공통 실행 흐름:
1. 시안 정의 (AI 제안 / 텍스트 파싱 / 이미지 분석)
2. 시안 정의 표시 → 사용자 확인
3. Stitch 프로젝트 1개 생성 → 핵심 화면 10개 배치 생성
4. .prism/preview/{name}/DESIGN.md + screenshots/ 저장
5. "활성화할까요?" → 선택 시 ./DESIGN.md로 복사
```

AI 제안 시: 기존 저장 시안과 중복되지 않는 방향을 제안하며, 시장 리서치(WebSearch) 결과를 근거로 안정(60%) + 창의(40%) 비율로 제안한다.

### A5: 프롬프트 최적화 — 공식 스킬 위임

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

```
Skill("enhance-prompt") 호출 1회
→ A4에서 작성한 원시 프롬프트를 전달
→ DESIGN.md 경로를 별도로 전달하지 않아도 됨
  (A4.5에서 선택한 시안이 ./DESIGN.md에 이미 존재하며,
   enhance-prompt 스킬이 자동으로 읽어서 디자인 토큰을 주입)
→ 결과를 .prism/prompts.md에 저장
```

### A6: 산출물 저장

**Goal:** 분석 결과를 저장하고 사용자 확인을 받는다.

**파일 구조:**

```
./DESIGN.md                      ← 활성 시안의 DESIGN.md 복사본 (프로젝트 최상위)
.prism/
  analysis.md                    ← 공통 (A1-A4 산출물)
  prompts.md                     ← A5 결과
  preview/                       ← A4.5 시안 저장
    index.md                     ← 시안 목록 + 프로젝트 ID + 활성 시안 표시
    {direction-name}/            ← 저장된 시안별 디렉토리
      DESIGN.md                  ← 해당 시안의 designTheme.designMd
      screenshots/               ← 해당 시안의 화면 스크린샷
  project-ids.md                 ← D3 생성 프로젝트 ID (Feature별)
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
→ 프로젝트 이름: "{App} · {시안명} · {Feature번호}. {Feature명}"
→ 예시: "{App} · Warm Organic · 1. Auth & Onboarding"
→ 예시: "{App} · Warm Organic · 2. Home"
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

**배치 프롬프트 예시 (도메인별):**

```
예시 A — 커머스 앱:
Design 5 primary screens for the Products feature of FreshCart — a grocery delivery app.

Clean, modern, appetizing atmosphere. Continue using the "Fresh Market" design system.

**Screen 1: 상품 목록 (그리드 뷰)**
2-column product grid with food images, names, prices, quantity steppers. Top category chips, floating cart button with badge, bottom navigation.

**Screen 2: 상품 목록 (리스트 뷰)**
Horizontal product cards with large image, name, price, weight. Add-to-cart button on each card.

**Screen 3: 상품 상세**
Hero product image, name, price, weight options. Nutrition info expandable section, related products carousel, sticky add-to-cart bar.

**Screen 4: 상품 검색**
Search bar with recent searches and voice input icon. Results as compact product cards with image, name, price.

**Screen 5: 카테고리 필터**
Full-screen category grid with icons and labels. Sub-category chips at top when category selected.

All UI text must be in Korean (한국어).
```

```
예시 B — 피트니스 앱:
Design 4 primary screens for the Dashboard feature of FitLog — a workout tracking app.

Energetic, bold, motivating atmosphere. Continue using the "Active Pulse" design system.

**Screen 1: 오늘 대시보드**
Top greeting with streak badge. Summary cards for calories, steps, active minutes with circular progress rings. Recent workout list below.

**Screen 2: 운동 기록 상세**
Workout type icon, duration, calories burned. Heart rate chart, exercise breakdown list with sets/reps.

**Screen 3: 주간/월간 통계**
Toggle tabs for week/month. Bar chart for daily activity, line chart for trend. Category breakdown donut chart.

**Screen 4: 목표 설정**
Goal type selection (칼로리, 걸음수, 운동 시간). Slider for target value, weekly schedule checkboxes.

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

7. **크레딧 소진 감지 및 안전 중단:**

   Stitch API가 rate limit 또는 크레딧 소진 에러를 반환하면:

   ```
   1. 현재 진행 상황을 상태 파일에 저장:
      - completed_screens: 이미 생성된 화면 목록 ("|" 구분)
      - current_axis: 현재 처리 중인 축 (primary/states/overlays/interactions)
      - project_id: 현재 Feature의 Stitch 프로젝트 ID
      - design_name: 현재 시안 이름 (DESIGN.md의 Name 필드)
   2. 상태 파일을 시안별 백업: .claude/prism-pipelines/{design_name}.local.md
   3. .prism/project-ids.md에 현재까지 생성된 프로젝트 ID 기록
   4. 사용자에게 안내:

      ⚠️ 크레딧이 소진되었습니다.

      시안: {design_name}
      진행 상황: Feature {current}/{total} ({feature_name}) — 축 {axis}, 화면 {n}개 생성 완료
      완료된 Feature: {completed_features}

      이어하기:
        1. /prism account <다른계정> → 세션 재시작
        2. /prism design resume

      또는 다른 시안으로 전환:
        1. /prism preview use <다른시안>
        2. /prism design all (새로 시작)
        나중에 돌아오기: /prism preview use {design_name} → /prism design resume
   ```

**시안별 상태 파일 관리:**

```
.claude/
  prism-design-pipeline.local.md     ← 현재 활성 (Stop hook이 읽는 파일)
  prism-pipelines/                   ← 시안별 상태 백업
    warm-organic.local.md
    editorial-elegance.local.md
```

- `/prism design all` 실행 시: ./DESIGN.md에서 시안 이름 추출 → 해당 시안의 상태 파일 로드 (있으면 resume, 없으면 신규)
- `/prism preview use <name>` 시안 전환 시: 현재 상태 파일을 `.claude/prism-pipelines/{현재시안}.local.md`에 백업 → 새 시안의 상태 파일을 활성화
- 모든 Feature 완료 시: 상태 파일 삭제 (활성 + 백업 모두)

**`/prism design resume` — 중단된 파이프라인 이어하기:**

```
1. .claude/prism-design-pipeline.local.md 존재 확인
   없으면 → "중단된 파이프라인이 없습니다." 안내
2. 상태 파일에서 진행 상황 읽기:
   - design_name: 시안 이름
   - feature: 현재 Feature
   - completed_features: 완료된 Feature 목록
   - completed_screens: 해당 Feature에서 이미 생성된 화면
   - current_axis: 중단된 축
   - project_id: 기존 Stitch 프로젝트 ID (있으면 재사용)
3. 현재 ./DESIGN.md의 시안 이름과 상태 파일의 design_name 일치 확인
   불일치 시 → 경고: "현재 활성 시안({현재})과 중단된 시안({상태})이 다릅니다. /prism preview use {상태} 후 resume하세요."
4. 진행 상황 표시:
   "시안: {design_name}"
   "Feature {current}/{total} ({name}) 이어서 생성합니다."
   "완료된 Feature: {list}"
   "이미 생성된 화면: {n}개"
5. 중단 지점부터 D3 재개:
   - project_id가 있으면 기존 프로젝트에 화면 추가
   - completed_screens에 있는 화면은 건너뛰기
   - 남은 축부터 배치 생성 계속
6. Feature 완료 후 정상 흐름으로 복귀 (D4-D6 → 다음 Feature)
```

### D4: 검증

**실행 주체:** prism 자체 (읽기 전용 MCP 직접 호출)

**Steps:**
1. 각 화면에 대해:
   ```
   get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/prism-{screenName}.png
   sips -Z 1200 /tmp/prism-{screenName}.png
   Read /tmp/prism-{screenName}.png → 시각 검증
   ```

2. 검증 체크리스트 (항목별 pass/fail → gaps 카운트):
   - [ ] 코드의 모든 Primary Screen이 Stitch 화면에 1:1 매핑되는가
   - [ ] 모든 버튼/인터랙션 요소가 디자인에 반영되었는가
   - [ ] 상태별 화면(empty, skeleton/loading, error)이 포함되었는가
   - [ ] 오버레이(바텀시트, 다이얼로그, 스낵바)가 누락 없이 있는가
   - [ ] UI 텍스트가 한국어인가 (영어 placeholder 잔존 여부)
   - [ ] 디자인 시스템(색상, 타이포, 간격)이 DESIGN.md와 일관적인가
   - [ ] 레이아웃이 모바일 비율(390×844)에 적합한가

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
"On the product list screen, make the grid 3 columns instead of 2."
"On the detail page, add a horizontal scroll of related items at the bottom."
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
