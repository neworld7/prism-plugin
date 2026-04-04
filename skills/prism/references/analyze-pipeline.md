# Analyze Pipeline — `/prism analyze [app]`

Analyze 파이프라인 실행 가이드. Phase A1-A12.
Design 파이프라인은 `references/design-pipeline.md` 참조.

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

# 오디오/미디어 재생 (플레이어, 파형, 녹음 UI)
Grep: AudioPlayer|just_audio|audioplayers|WaveformView|waveform|RecordButton|record|VoiceRecorder|AmbientPlayer|MusicPlayer|audio_session

# 카드 플립/스와이프 (학습 카드, 매칭 UI)
Grep: FlipCard|flip_card|FlashCard|flashcard|CardSwiper|swipe_card|TweenAnimationBuilder.*transform|AnimatedSwitcher
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

**각 축에서 발견된 코드 위치를 아래 형식으로 정리**하여 A8의 입력 데이터로 사용한다.

**Output 형식 (A1 → A8 전달 구조):**

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

**중요:** 표가 비어있는 축도 반드시 포함한다. 빈 축은 A8에서 "코드에는 없지만 앱에 필요한 화면"을 추가하는 힌트가 된다.

### A2: Functional Scan

**Goal:** A1의 grep 결과는 "어떤 화면이 있는지"만 알려준다. A2는 각 화면 파일을 **실제로 읽어서** 기능적 요소(버튼, 데이터 필드, 인터랙션, 네비게이션 흐름)를 추출한다. 이 정보가 없으면 A9 프롬프트가 "버튼 있음" 수준에 머물러 실제 기능이 디자인에서 누락된다.

> **⚠️ 핵심 교훈 (v3.4.3):** A1 grep만으로는 화면의 **기능적 의미**를 파악할 수 없다. "showModalBottomSheet가 있다"는 것은 알지만, 그 바텀시트에 **무엇이 들어있는지**(정렬 옵션인지, 삭제 확인인지, 상태 변경인지)는 파일을 읽어야 알 수 있다. 이 단계를 건너뛰면 프롬프트가 레이아웃만 기술하고 기능을 누락한다.

**Steps:**

1. A1에서 발견된 **Primary Screen 파일 전부를 Read**한다 (`.g.dart`, `.freezed.dart` 제외):

```
A1에서 발견된 각 Primary Screen 파일에 대해:
  Read: {파일 경로} (전체 읽기 또는 build() 메서드 중심)
```

2. 각 파일에서 **5가지 기능 요소**를 추출한다:

| 요소 | 추출 방법 | 프롬프트에서의 역할 |
|------|----------|-------------------|
| **버튼/액션** | `onPressed`, `onTap`, `ElevatedButton`, `TextButton`, `IconButton` + 라벨 텍스트 | "어떤 버튼이 어떤 동작을 하는지" 기술 |
| **데이터 필드** | `Text(`, `TextField`, `TextFormField` + 표시 내용 | "화면에 어떤 정보가 보이는지" 기술 |
| **네비게이션** | `context.push`, `context.go`, `GoRoute`, `Navigator.pop` + 목적지 | "이 화면에서 어디로 이동하는지" 기술 |
| **조건부 UI** | `if (`, `? :`, `when:`, `switch`, `Visibility`, `Offstage` + 조건 | "언제 무엇이 보이고 안 보이는지" 기술 |
| **오버레이 내용** | `showModalBottomSheet` ~ 닫는 괄호 내부, `showDialog` 내부 | "바텀시트/다이얼로그에 뭐가 들어있는지" 기술 |

3. **A2 Output** — 각 Primary Screen별 기능 카드:

```markdown
## A2 Functional Scan

### {ScreenName} ({파일 경로})

**버튼/액션:**
| 라벨 | 동작 | 코드 위치 |
|------|------|----------|
| "시작하기" | 상태 변경 + 진행 시작 | detail_screen.dart:420 |
| "삭제" | 삭제 확인 다이얼로그 | detail_screen.dart:634 |

**데이터 필드:**
| 필드 | 내용 | 소스 |
|------|------|------|
| 제목 | item.title (Display font) | detail_screen.dart:180 |
| 부제 | item.subtitle | detail_screen.dart:185 |
| 진행률 | "${item.progress}%" | detail_screen.dart:210 |

**네비게이션:**
| 목적지 | 트리거 | 라우트 |
|--------|--------|-------|
| 에디터 | "편집" 버튼 탭 | /items/{id}/edit |
| 상세 목록 | "목록" 탭 탭 | /items/{id}/list |
| 진행 화면 | "시작하기" 버튼 | /items/{id}/progress |

**조건부 UI:**
| 조건 | 표시 | 숨김 |
|------|------|------|
| item.status == active | 진행률 바, "이어하기" 버튼 | "시작하기" 버튼 |
| item.status == completed | 완료 배지, 리뷰 버튼 | 진행률 바 |

**오버레이 내용:**
| 유형 | 내용 | 트리거 |
|------|------|--------|
| bottom-sheet | 상태 선택: 진행 중/대기/완료/중단 | 상태 칩 탭 |
| dialog | "이 항목을 삭제하시겠어요?" + 확인/취소 | 더보기 > 삭제 |
| bottom-sheet | 관련 기록 목록 | 기록 아이콘 탭 |
```

4. **A2 → A9 연결:** A9 프롬프트 작성 시 A2의 기능 카드를 참조하여:
   - 버튼 라벨과 위치를 프롬프트에 포함
   - 데이터 필드를 한국어 실제 텍스트로 표현
   - 조건부 UI 상태별 화면을 별도 프롬프트로 생성
   - 오버레이 내용을 구체적으로 기술 (예: "삭제 확인 다이얼로그" → "이 책을 삭제하시겠어요?" 텍스트 + 확인/취소 버튼)

> **실용적 적용:** Primary Screen이 많을 경우 (20개+), 핵심 화면(P0 우선순위)만 Deep Scan하고 나머지는 A1 grep 결과만 사용해도 된다. 단, 바텀시트/다이얼로그의 내용은 반드시 읽어야 한다 — grep으로는 "존재"만 알고 "내용"은 알 수 없기 때문이다.

### A3: Navigation Flow

**Goal:** 라우터 파일을 읽어서 화면 간 이동 맵(Navigation Flow Graph)을 생성한다. 이 정보가 없으면 각 화면이 고립된 디자인이 되어 뒤로가기, 딥링크, 탭 전환 등의 흐름이 누락된다.

**Steps:**

1. **라우터 파일 탐색 및 Read:**
```
Flutter: Glob: **/router.dart, **/routes.dart, **/app.dart (GoRouter 정의)
React:   Glob: **/routes.{tsx,jsx}, **/App.{tsx,jsx} (React Router 정의)
Next.js: Glob: app/**/page.{tsx,jsx} + app/**/layout.{tsx,jsx} (파일 기반 라우팅)
```

2. **추출할 요소:**

| 요소 | 추출 방법 | 역할 |
|------|----------|------|
| **라우트 트리** | GoRoute 중첩 구조, path 파라미터 | 부모-자식 화면 관계 |
| **네비게이션 셸** | StatefulShellRoute, BottomNavigationBar | 탭 구조, 병렬 네비게이션 |
| **딥링크** | path 파라미터 `:id`, `/:slug` | 외부에서 진입 가능한 화면 |
| **리다이렉트** | redirect, guard 로직 | 인증 필요 화면, 조건부 진입 |

3. **A3 Output — Navigation Flow Graph:**

```markdown
## A3 Navigation Flow Graph

### 탭 구조
| 탭 | 경로 | 화면 |
|----|------|------|
| 0 | / | HomeScreen (LibraryScreen) |
| 1 | /stats | StatsScreen |
| 2 | /learning | LearningTabScreen |
| 3 | /community | CommunityScreen |
| 4 | /profile | ProfileScreen |

### 라우트 트리 (들여쓰기 = 부모-자식)
```
/ (HomeScreen)
  ├── items/add → AddScreen
  │   └── register → RegisterScreen
  ├── items/:id → DetailScreen
  │   ├── edit → EditScreen
  │   ├── timer → TimerScreen → complete → CompletionScreen
  │   ├── notes → NotesListScreen
  │   └── search → SearchScreen
/settings → SettingsScreen
  ├── export → ExportScreen
  └── subscription → SubscriptionScreen
/ai/chat → ChatScreen
  └── :conversationId → ChatDetailScreen
```

### 인증 가드
| 경로 | 가드 | 미인증 시 |
|------|------|----------|
| /* (전체) | isLoggedIn | → /login |
| /login | !isLoggedIn | → / |
| /onboarding | !isOnboardingComplete | → / |
```

> **A3 → A9 연결:** 프롬프트에서 "Back" 버튼, 탭 바 구조, 하위 화면 개수를 정확히 기술할 수 있다. 또한 딥링크 가능한 화면은 독립적으로 렌더링되어야 하므로 헤더/네비게이션이 완전해야 한다.

> **A3 → A12 연결 (필수):** Navigation Flow Graph와 User Flows 테이블은 **반드시 analysis.md에 포함**한다. 이 데이터가 없으면 design-pipeline D2의 Flow 매핑이 작동하지 않는다. A3 산출물은 A9 프롬프트 생성에만 사용하는 것이 아니라, analysis.md의 "Navigation Flow Graph" 및 "User Flows" 섹션으로 영구 저장해야 한다.

4. **User Flows 추출 (A3 확장):**

A2에서 수집한 네비게이션 목적지(`context.push`, `context.go`)와 라우트 트리를 조합하여 Cross-Feature User Flow를 자동 추출한다.

```
추출 기준:
1. 인증/온보딩 → 첫 도착 화면까지의 완전 경로
2. 핵심 가치 루프: 메인 콘텐츠 CRUD → 핵심 인터랙션 → 완료 사이클
3. Multi-State 연속 화면 (3개+): 타이머, 카메라/OCR, 온보딩 페이지
4. Feature 경계를 넘는 네비게이션 (예: 서재 → 상세 → 타이머 → 완료 → 통계)
5. 페이월/구독 라운드트립
6. 소셜 진입 경로 (탐색 → 가입 → 참여)

출력 형식:
| # | Flow | Screens | Entry | Exit | 관련 Feature |
|---|------|---------|-------|------|-------------|
| F1 | 첫 사용 | 0-01→0-04→0-05→0-06→0-07→1-01 | 앱 최초 실행 | 서재 도착 | F0→F1 |
```

### A4: Data Model

**Goal:** 엔티티/모델 클래스를 읽어서 각 화면에 표시되는 데이터의 구조와 관계를 파악한다. 이 정보가 없으면 프롬프트에서 "제목, 저자" 같은 추상적 표현만 가능하고, 실제 데이터 필드(ISBN, 출판일, 장르 enum 등)를 놓친다.

**Steps:**

1. **모델/엔티티 파일 탐색 및 Read:**
```
Flutter: Glob: **/domain/*_entity.dart, **/models/*.dart, **/tables/*_table.dart
React:   Glob: **/types/*.ts, **/models/*.ts, **/schema/*.ts
Next.js: Glob: **/prisma/schema.prisma, **/drizzle/schema.ts
```

2. **추출할 요소:**

| 요소 | 추출 방법 | 역할 |
|------|----------|------|
| **필드 목록** | 클래스 프로퍼티, 컬럼 정의 | 화면에 표시할 데이터 항목 |
| **필드 타입** | String, int, DateTime, enum | 데이터 포맷 (날짜, 숫자, 상태 칩 등) |
| **Enum 값** | enum Status { active, completed, ... } | 상태 필터, 칩, 드롭다운 옵션 |
| **관계** | hasMany, belongsTo, ForeignKey | 화면 간 데이터 연결 (상세→목록) |
| **Nullable 필드** | String?, int? | 선택적 UI 요소 (없으면 숨김) |

3. **A4 Output — Data Model Map:**

```markdown
## A4 Data Model Map

### Core Entities

**ItemEntity**
| 필드 | 타입 | UI 표현 |
|------|------|--------|
| id | String (UUID) | 숨김 |
| title | String | Display font, 메인 제목 |
| subtitle | String? | Body font, 부제 (nullable → 없으면 숨김) |
| coverUrl | String? | 이미지 (nullable → 플레이스홀더) |
| status | StatusEnum | 상태 칩/필터 |
| progress | int (0-100) | 프로그레스 바 |
| createdAt | DateTime | "N일 전" 형식 |
| categoryId | FK → Category | 카테고리 라벨 |

**StatusEnum**: active, pending, completed, paused
→ UI: 필터 탭 4개, 상태 변경 바텀시트 4옵션

### Relations
| 부모 | 자식 | 관계 | UI 영향 |
|------|------|------|--------|
| Item | Note | 1:N | 상세 화면에 노트 수 표시, 노트 목록 탭 |
| Item | Quote | 1:N | 인용 목록 화면 |
| User | Item | 1:N | 서재 전체 목록 |
| Group | Item | N:N | 그룹별 분류 |
```

> **A4 → A9 연결:** 프롬프트에서 데이터 필드를 정확한 타입으로 기술할 수 있다. 예: "progress as horizontal bar (0-100%)", "status chip with 4 options: active/pending/completed/paused", "createdAt as relative time '3일 전'". Nullable 필드는 empty 상태 화면의 근거가 된다.

### A5: String & Copy

**Goal:** 앱의 실제 한국어 텍스트(빈 상태, 에러, 버튼 라벨, 토스트 등)를 수집하여 앱의 **어투/보이스 톤**을 파악한다. 이 정보가 없으면 Stitch가 텍스트를 자체 창작하여 앱의 톤과 불일치하는 문구를 생성한다.

**Steps:**

1. **텍스트 소스 탐색 및 Read:**
```
Flutter: Glob: **/l10n/*.arb, **/generated/app_localizations*.dart
React:   Glob: **/locales/*.json, **/i18n/*.ts
Next.js: Glob: **/messages/*.json, **/dictionaries/*.ts
공통:    Grep: '아직.*없|등록된.*없|없어요|없습니다|실패|오류|불러올 수|시작하기|확인|취소' in lib/ or src/
```

2. **추출할 요소:**

| 요소 | 추출 방법 | 역할 |
|------|----------|------|
| **빈 상태 메시지** | "아직", "없어요", "없습니다" 패턴 | empty 화면의 정확한 문구 |
| **에러 메시지** | "실패", "오류", "불러올 수 없" 패턴 | error 화면의 정확한 문구 |
| **버튼 라벨** | "시작하기", "저장", "취소", "확인" 등 | 버튼 텍스트 정확히 반영 |
| **어투 패턴** | 존댓말(-요)/반말(-다)/친근(-해봐요) 분석 | 앱 전체 톤 일관성 |
| **섹션 제목** | AppBar title, 헤더 텍스트 | 네비게이션 라벨 정확히 반영 |

3. **A5 Output — Copy Inventory:**

```markdown
## A5 Copy Inventory

### 어투 분석
| 패턴 | 빈도 | 예시 |
|------|------|------|
| 친근 존댓말 (-어요/해요) | 높음 | "아직 등록된 항목이 없어요", "시작해보세요" |
| 정중 존댓말 (-습니다) | 중간 | "검색 결과가 없습니다", "삭제되었습니다" |
| 명령형 (-하기) | 낮음 | "시작하기", "저장하기" |

**앱 보이스**: 친근한 존댓말 (-어요) 기반. 사용자에게 격려하는 톤.

### 빈 상태 메시지 (Feature별)
| Feature | 화면 | 메시지 |
|---------|------|--------|
| Home | 메인 목록 | "아직 등록된 항목이 없어요" |
| Home | 검색 결과 | "검색 결과가 없습니다" |
| Social | 피드 | "아직 활동 기록이 없어요" |

### 에러 메시지
| 유형 | 메시지 |
|------|--------|
| 로드 실패 | "불러올 수 없어요" |
| 네트워크 | "오프라인입니다" |
| 인증 | "로그인에 실패했습니다" |

### 주요 버튼 라벨
| 라벨 | 용도 | 빈도 |
|------|------|------|
| "시작하기" | Primary CTA | 높음 |
| "저장" | 폼 제출 | 높음 |
| "취소" | 액션 취소 | 높음 |
| "삭제" | 위험 액션 | 중간 |
```

> **A5 → A9 연결:** 프롬프트에서 Stitch가 텍스트를 창작하지 않도록 **실제 앱 문구를 그대로** 포함한다. 특히 빈 상태 메시지와 에러 메시지는 앱 톤의 핵심이므로 정확히 전달해야 한다. 또한 앱 보이스(친근 존댓말 vs 정중 존댓말)를 프롬프트에 명시하여 Stitch가 일관된 톤으로 텍스트를 생성하도록 한다.
>
> **다국어 앱 가이드:** 앱이 여러 언어를 지원하더라도(l10n/i18n), **디자인은 주 언어(primary locale) 기준으로만 생성한다.** 이유: (1) 디자인 시안의 목적은 레이아웃과 시각적 톤을 결정하는 것이지 모든 언어를 검증하는 것이 아니다, (2) 텍스트 길이 차이(예: 한국어 4글자 vs 영어 11글자)에 의한 레이아웃 깨짐은 구현 단계에서 responsive 처리로 해결한다. A5에서는 주 언어 텍스트만 수집하되, l10n 파일이 존재하면 **지원 언어 수와 주 언어**를 analysis.md에 기록한다.

### A6: Layout Architecture

**Goal:** 각 화면의 최상위 레이아웃 위젯(스크롤 구조, 앱바 유형, 탭 구조)을 감지하여 화면의 **물리적 구조**를 파악한다. SliverAppBar인지 일반 AppBar인지에 따라 디자인이 근본적으로 달라진다.

**Steps:**

1. **각 Primary Screen 파일에서 레이아웃 위젯 grep:**
```
Flutter:
  Grep: CustomScrollView|SliverAppBar|SliverList|SliverGrid in lib/
  Grep: TabBarView|TabBar|DefaultTabController in lib/
  Grep: PageView|PageController in lib/
  Grep: NestedScrollView in lib/
  Grep: SingleChildScrollView in lib/
  Grep: ListView\.builder|GridView\.builder in lib/

React:
  Grep: overflow-y-scroll|overflow-auto|sticky|position.*fixed in src/
  Grep: InfiniteScroll|VirtualList|useInfiniteQuery in src/

Next.js:
  Grep: scroll|sticky|fixed in app/
```

2. **추출할 요소:**

| 요소 | 감지 패턴 | 디자인 영향 |
|------|----------|------------|
| **SliverAppBar** | `SliverAppBar`, `expandedHeight`, `flexibleSpace` | 축소되는 헤더 — 스크롤 시 줄어드는 히어로 영역 |
| **TabBarView** | `TabBar`, `TabBarView`, `DefaultTabController` | 스와이프 가능한 탭 레이아웃 |
| **PageView** | `PageView`, `PageController` | 풀스크린 카드 캐러셀 (좌우 스와이프) |
| **NestedScrollView** | `NestedScrollView` | 복합 스크롤 (헤더 + 탭 + 스크롤 리스트) |
| **무한 스크롤** | `ListView.builder`, `ScrollController`, `addListener` | 페이지네이션 표시 필요 |
| **고정 요소** | `bottomSheet`, `persistentFooterButtons`, `FloatingActionButton` | 하단 고정 바 |

3. **A6 Output — Layout Architecture:**

```markdown
## A6 Layout Architecture

| 화면 | 스크롤 유형 | 앱바 | 특수 구조 | 고정 요소 |
|------|-----------|------|----------|----------|
| HomeScreen | CustomScrollView | SliverAppBar (축소) | — | FAB |
| DetailScreen | NestedScrollView | SliverAppBar + TabBar | 3탭 (소개/메모/인용) | 하단 액션 바 |
| ListScreen | ListView.builder | 일반 AppBar | 무한 스크롤 | — |
| EditorScreen | SingleChildScrollView | 일반 AppBar | 키보드 대응 | 하단 툴바 |
| TimerScreen | 스크롤 없음 | 없음 | 풀스크린 | 하단 컨트롤 |
| StatsScreen | CustomScrollView | SliverAppBar | SliverGrid + SliverList 혼합 | — |
```

> **A6 → A9 연결:** 프롬프트에서 "scrollable page with collapsible header" vs "fixed full-screen layout" vs "tabbed content with swipe" 등을 정확히 기술할 수 있다. SliverAppBar가 있는 화면은 반드시 "hero image that collapses on scroll" 패턴을 포함해야 하고, PageView가 있는 화면은 "horizontal carousel with peek" 패턴을 사용해야 한다.

### A7: Package Detection

**Goal:** 의존성 파일(pubspec.yaml, package.json)에서 **UI 렌더링에 영향을 주는 외부 패키지**를 감지한다. 차트, 카메라, 지도 등의 패키지는 표준 위젯과 다른 커스텀 렌더링 영역을 생성하므로 프롬프트에서 별도 처리해야 한다.

**Steps:**

1. **의존성 파일 Read:**
```
Flutter: Read: pubspec.yaml → dependencies 섹션
React:   Read: package.json → dependencies + devDependencies
Next.js: Read: package.json → dependencies
```

2. **UI 영향 패키지 분류:**

| 카테고리 | 패키지 예시 | 프롬프트 영향 |
|---------|-----------|-------------|
| **차트** | fl_chart, syncfusion_charts, charts_flutter, recharts, chart.js | "차트 영역" → 구체적 차트 타입 기술 필요 |
| **카메라** | camera, image_picker, mobile_scanner | "카메라 뷰파인더" 영역 필요 |
| **지도** | google_maps_flutter, flutter_map, mapbox | "지도 영역" 필요 |
| **비디오** | video_player, chewie, better_player | "비디오 플레이어" 영역 필요 |
| **리치 텍스트** | flutter_quill, super_editor, tiptap | "리치 텍스트 에디터 + 툴바" 영역 필요 |
| **OCR/ML** | google_mlkit_text_recognition, tflite | "카메라 + 텍스트 오버레이" 영역 필요 |
| **결제** | purchases_flutter (RevenueCat), stripe | "페이월/구독 화면" 존재 |
| **소셜 로그인** | google_sign_in, sign_in_with_apple | "소셜 로그인 버튼" 필요 |
| **오디오/미디어** | just_audio, audioplayers, audio_session, record, flutter_sound | "오디오 플레이어 + 파형/진행 바" 영역 필요 |
| **학습/플래시카드** | flip_card, swipe_card, flutter_flip_card | "카드 전면/후면 플립" 상태 필요 |

3. **A7 Output — External Package Report:**

```markdown
## A7 External Packages (UI-Affecting)

| 패키지 | 카테고리 | 사용 화면 | 프롬프트 반영 |
|--------|---------|----------|-------------|
| fl_chart | 차트 | StatsScreen | 막대/선/원 차트 영역, 축 라벨 |
| camera | 카메라 | OcrCaptureScreen | 카메라 뷰파인더 + 프레임 오버레이 |
| mobile_scanner | 바코드 | BarcodeScannerScreen | 바코드 스캔 뷰파인더 |
| purchases_flutter | 결제 | SubscriptionScreen | 구독 플랜 비교 카드, 구매 버튼 |
| google_sign_in | 인증 | LoginScreen | Google 로고 소셜 로그인 버튼 |
| flutter_quill | 리치 텍스트 | NoteEditorScreen | 에디터 + 포맷 툴바 |
| google_mlkit_text_recognition | OCR | OcrResultScreen | 인식된 텍스트 하이라이트 오버레이 |
| just_audio | 오디오 | AmbientPlayerScreen | 오디오 파형 + 재생/일시정지 컨트롤 + 진행 바 |
| flip_card | 플래시카드 | FlashcardScreen | 카드 전면(단어)/후면(뜻) 플립 UI |
```

> **A7 → A9 연결:** 외부 패키지가 렌더링하는 영역은 Stitch가 일반 위젯으로 대체하면 안 된다. 프롬프트에서 "chart area showing bar chart with X-axis labels" 또는 "camera viewfinder with rectangular scan frame overlay" 등으로 구체적으로 기술해야 한다. 또한 RevenueCat 등 결제 패키지가 있으면 구독/페이월 화면이 존재한다는 것을 A8 Feature Separation에서 반영해야 한다.
>
> **오디오/미디어 패키지** → `Audio player with waveform visualization, play/pause button at center, progress bar below. Background artwork or album art above player.` (절대 빈 화면이나 단순 아이콘으로 대체하지 않음)
> **학습/플래시카드 패키지** → `Card with front face showing {term} in large display font. Back face (separate screen) showing {definition} with example sentence. Flip indicator at bottom.` 전면/후면을 각각 별도 화면으로 생성.

### A8: Feature Separation

**Goal:** A1~A7의 **모든 분석 결과**를 통합하여 Feature 단위로 화면을 분류한다. A1(grep) 결과만이 아니라 A2(기능), A3(네비), A4(데이터), A5(텍스트), A6(레이아웃), A7(패키지)을 모두 반영한 **풍부한 화면 카드**를 생성한다.

> **⚠️ 핵심 (v3.5.1):** A8은 단순한 "화면 이름 목록"이 아니라, A9 프롬프트 작성을 위한 **완전한 화면 명세**다. A8 Output에 정보가 부족하면 A9 프롬프트도 부족해진다.

**Steps:**

1. 화면을 기능 단위(Feature)로 그룹화한다. **Feature 분리 기준:**
   - 앱의 **하단 네비게이션 탭** 또는 **주요 섹션**이 자연스러운 Feature 경계 ← **A3 탭 구조 참조**
   - 코드 폴더 구조 (`features/auth/`, `features/home/`, `features/stats/`)가 가장 신뢰할 수 있는 기준
   - **Feature는 코드 구조를 존중한다** — 코드에 독립 폴더가 있으면 독립 Feature로 유지
   - Feature 0: Common/System (스플래시, 오프라인, 강제 업데이트 등 공통 화면)
   - **A7 패키지 기반 화면 추가**: 결제 패키지 → 구독/페이월 화면, 카메라 패키지 → 캡처 화면 등을 해당 Feature에 명시적으로 포함

   **적응형 분리 규칙 (대형 앱 대응):**
   - **대형 Feature 분할**: Screen State Matrix 적용 후 화면이 **25개를 초과**하면 사용자 흐름 기준으로 Sub-Feature로 분할한다. 예: Clubs(30+ 화면) → "Clubs-Core"(목록/상세/생성/설정) + "Clubs-Social"(토론/이벤트/투표/지식공유). 각 Sub-Feature는 별도 Stitch 프로젝트가 된다.
   - **소형 Feature 합치기**: Primary Screen이 **0~2개**이고 presentation 폴더에 화면 파일이 없는 Feature(data layer only, 빈 화면 1개 등)는 **인접 Feature에 합치거나 Feature 0(Common)에 포함**할 수 있다. 예: Explore(1개 빈 화면) → Home에 합치기, Focus(0개) → 디자인 대상에서 제외.
   - **합치기 판단 기준**: (1) 코드 폴더에 `presentation/` 디렉토리가 없거나 비어있음, (2) Screen State Matrix 적용 후 화면이 5개 미만, (3) 독립 Stitch 프로젝트로 만들면 크레딧 대비 가치가 낮음. 세 조건 중 2개 이상 해당되면 합치기 대상.
   - **분할 규칙**: 합치기와 별개로, Primary Screen이 10개 이상이면 사용자 흐름 기준으로 분할을 검토한다.

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
   - 삭제/수정 액션이 있는 화면 ← **A2 버튼/액션 참조**: 확인 다이얼로그 필수 추가
   - 검색 기능이 있는 화면 ← **A2 인터랙션 참조**: `search-active`, `검색 결과 없음` 필수 추가
   - 리스트/그리드 화면: `empty`, `partial`, `skeleton`, 필터/정렬 오버레이 필수 추가
   - 폼 화면: `keyboard-visible` (입력 포커스), 유효성 에러 상태 필수 추가
   - 인증 분기가 있는 화면 ← **A1 축6 Auth 참조**: 비로그인/무료/프리미엄 변형 중 UI가 크게 달라지는 것만 추가
   - 외부 패키지 화면 ← **A7 참조**: 차트/카메라/지도/결제 패키지가 있으면 해당 화면을 명시적으로 포함
   - **Feature 배정 규칙**: 특정 Feature에 속하지 않는 공통 화면은 **"0. Common / System"** Feature에 배정

   **구독/Premium 게이팅 화면 자동 도출 (축 6 확장):**
   A1 축6에서 `isPremium`, `isSubscribed`, `hasFeature`, `paywall`, `entitlement`, `freeTier` 패턴이 감지된 화면에 대해, **UI가 크게 달라지지 않더라도** 다음 요소가 있으면 free-tier 변형 화면을 생성한다:
   - **잠금 오버레이**: 프리미엄 기능에 잠금 아이콘 + "Pro" 배지가 표시되는 화면 → `{화면명} (free — 잠금 오버레이)` 추가
   - **사용량 제한 배너**: 무료 사용자에게 "N/M회 사용" 진행 바 + 업셀 배너가 표시되는 화면 → `{화면명} (free — 사용량 바 + 업셀)` 추가
   - **기능 제한 표시**: 일부 UI 요소가 비활성화(dimmed)되거나 "Pro" 라벨이 붙는 화면 → `{화면명} (free — 기능 제한)` 추가
   판단 기준: A2 Functional Scan에서 조건부 UI(`if isPremium`) 내부에 **시각적 변화**(아이콘, 배너, 비활성화)가 있으면 별도 화면. 단순히 기능이 숨겨지기만 하면(버튼 자체가 안 보임) 별도 화면 불필요.

4. **화면 수 목표:**
   - **Feature당 15~20개** 화면 (Primary + States + Overlays + Interaction Modes)
   - **전체 앱 화면 수 제한 없음** — Feature별 독립 Stitch 프로젝트이므로 관리 부담 없음
   - Feature당 화면이 12개 미만이면 Screen State Matrix를 재검토하여 빠진 화면이 없는지 확인
   - Feature당 화면이 25개 이상이면 위 적응형 분리 규칙에 따라 Sub-Feature로 분할

**화면은 삭제하지 않는다.** 모든 화면이 디자인 → 코드 구현에 직접 활용되므로 우선순위에 의한 제거 없음.

5. 각 Feature의 화면을 **확장 카드 형식**으로 정리한다. A1~A7의 분석 결과를 통합하여 A9가 바로 참조할 수 있는 수준의 정보를 포함한다.

**Output — 확장 화면 테이블 (A1~A7 통합):**

```markdown
## Feature 2: {Feature명} ({N}개)

| # | 화면 | 축 | 레이아웃 | 주요 기능 | 핵심 텍스트 | 소스 |
|---|------|---|---------|----------|-----------|------|
| 1 | 메인 목록 (그리드 뷰) | Primary | CustomScrollView + SliverAppBar | 2열 그리드, FAB 추가, 필터 탭 | "전체 N건" | 코드 |
| 2 | 메인 목록 (리스트 뷰) | Primary | ListView.builder | 썸네일+제목+부제+진행률 | — | 코드 |
| 3 | 상세 | Primary | NestedScrollView + TabBar(3탭) | 4개 액션 버튼 → 에디터/타이머/목록/검색 | "시작하기", "삭제" | 코드 |
| 4 | 검색 | Primary | SingleChildScrollView | 검색바 + 자동완성 + 결과 리스트 | — | 코드 |
| 5 | 메인 목록 (empty) | Data: empty | 고정 (스크롤 없음) | CTA 1개 | "아직 등록된 항목이 없어요" | A5 |
| 6 | 메인 목록 (partial) | Data: partial | 그리드 (1-2개만) | — | — | 디자인 필수 |
| 7 | 메인 목록 (skeleton) | Data: skeleton | CustomScrollView | 시머 플레이스홀더 | — | 디자인 필수 |
| 8 | 검색 (결과 없음) | Data: empty | 고정 | — | "검색 결과가 없습니다" | A5 |
| 9 | 상세 (error) | Data: error | 고정 | 재시도 버튼 | "불러올 수 없어요" | A5 |
| 10 | 정렬 바텀시트 (최근/제목/저자순) | Overlay | 바텀시트 | 3개 정렬 옵션 + 적용 버튼 | — | A2 |
| 11 | 삭제 확인 ("이 항목을 삭제하시겠어요?") | Overlay | 다이얼로그 | 확인/취소 | "삭제하시겠어요?" | A2+A5 |
| 12 | 상태 변경 (진행 중/대기/완료/중단) | Overlay | 바텀시트 | 4개 enum 옵션 | — | A2+A4 |
| 13 | 메인 목록 (edit mode) | Interaction | 그리드 + 상단 액션 바 | 다중 선택 + 삭제/이동 | "N건 선택됨" | 코드 |
| 14 | 메인 목록 (search active) | Interaction | 검색바 확장 + 필터 | 실시간 필터링 | — | 코드 |
| 15 | 메인 목록 (비로그인) | Auth | 고정 | CTA 1개 | "로그인하고 시작해보세요" | A5 |
```

**열 설명:**
| 열 | 소스 | 역할 |
|----|------|------|
| **화면** | A1 (grep) | 화면 이름 + 상태 |
| **축** | A8 (Matrix 7축) | 어떤 축에 해당하는지 |
| **레이아웃** | A6 | SliverAppBar/TabBar/PageView/ListView 등 |
| **주요 기능** | A2 | 버튼, 인터랙션, 네비게이션 목적지 |
| **핵심 텍스트** | A5 + A2 | 실제 한국어 문구 (빈 상태, 에러, 버튼 라벨) |
| **소스** | A1~A7 | 어디서 도출되었는지 (코드/디자인 필수/분석 단계) |

> **A8 → A9 연결:** A9는 이 확장 테이블의 **각 행**을 하나의 Screen 프롬프트로 변환한다. 테이블에 정보가 충분하면 A9에서 추가 조사가 불필요하다.

### A9: Prompt Writing

**Goal:** 각 화면에 대해 **기능적으로 정확한** Stitch 프롬프트를 작성한다. A2 Functional Scan의 기능 카드를 반드시 참조한다.

> **⚠️ A2 참조 필수 (v3.4.3):** A2에서 추출한 버튼 라벨, 데이터 필드, 오버레이 내용을 프롬프트에 반영해야 한다. A2 없이 프롬프트를 작성하면 "버튼이 있다" 수준의 추상적 프롬프트가 되어 실제 기능이 디자인에서 누락된다.

**A2~A7 → A9 통합 매핑 규칙:**

각 분석 단계의 결과를 프롬프트의 **PAGE STRUCTURE** 블록에 어떻게 반영하는지 정의한다.

**From A2 (Functional Scan):**
- **버튼**: 한국어 라벨 그대로 + 스타일 (예: `"시작하기" primary filled button`, `"삭제" danger text button`)
- **데이터**: 실제 예시 데이터 + 폰트 역할 (예: `Title "항목 제목" in display font, subtitle "부제" in body font`)
- **조건부 UI**: 상태별로 별도 Screen 프롬프트 생성 (예: active 상태 화면, completed 상태 화면)
- **오버레이 내용**: 실제 옵션/메시지 포함 (예: `Bottom sheet with 4 status options: 진행 중, 대기, 완료, 중단`)

**From A3 (Navigation Flow):**
- **탭 구조**: 화면이 탭 네비게이션 안에 있으면 `Bottom tab bar with N tabs, {탭명} active` 필수 포함
- **Back 버튼**: 자식 화면이면 `Back arrow in top-left leading to {부모 화면명}` 포함
- **하위 화면 수**: 상세 화면에서 이동 가능한 목적지 수 (예: `4 action rows leading to: editor, timer, notes, quotes`)
- **딥링크 가능**: 독립 진입 가능한 화면은 `Full navigation context (header + tabs) must be visible — this screen can be entered directly via deep link` 명시
- **인증 가드**: 미인증 접근 불가 화면은 Auth 상태 화면을 별도 생성

**From A4 (Data Model):**
- **필드 타입 → UI 위젯 매핑**:
  - `String` → text label
  - `int (0-100)` → horizontal progress bar with percentage
  - `DateTime` → relative time "3일 전" or formatted date
  - `enum { a, b, c, d }` → filter chips / status selector with N options
  - `String?` (nullable) → "shown only when available, hidden otherwise"
  - `List<T>` → "scrollable list of N items" or "count badge showing N"
- **관계 → 네비게이션**: `Item hasMany Notes` → 상세 화면에 "N개 메모" 카운트 표시 + 메모 목록 링크
- **Enum → 오버레이 옵션**: `StatusEnum { active, pending, completed, paused }` → 바텀시트에 정확히 4개 옵션

**From A5 (String & Copy):**
- **빈 상태 문구**: A5에서 수집한 실제 메시지를 프롬프트에 그대로 포함 (예: `Empty state: "아직 등록된 항목이 없어요" centered in display font, "첫 번째 항목을 추가해보세요" subtitle below`)
- **에러 문구**: 실제 에러 메시지 포함 (예: `Error card: "불러올 수 없어요" with retry button`)
- **앱 보이스 톤**: 프롬프트 상단에 명시 (예: `App voice: friendly Korean (존댓말 -어요 tone). All placeholder text must match this voice.`)
- **버튼 라벨**: A5에서 수집한 정확한 한국어 라벨 사용 (A2와 교차 검증)

**From A6 (Layout Architecture):**
- **SliverAppBar** → `Collapsible hero header that shrinks from {expanded}px to toolbar height on scroll. Cover image in flexible space.`
- **TabBarView** → `{N}-tab swipeable content area. Tab labels: {탭1}, {탭2}, {탭3}. Active tab indicator in primary color.`
- **PageView** → `Horizontal full-width card carousel with peek of adjacent cards. Page indicator dots below.`
- **NestedScrollView** → `Complex scroll: collapsible header above, pinned tab bar in middle, scrollable list below.`
- **ListView.builder** → `Infinite scrolling vertical list. Loading indicator at bottom when fetching more.`
- **스크롤 없음** → `Fixed full-screen layout, no scrolling. All content visible without scroll.`
- **고정 요소** → `Sticky bottom bar with {내용}` 또는 `Floating action button at bottom-right`

**From A7 (Package Detection):**
- **차트 패키지** → `Chart area: {chart type} chart showing {data description}. X-axis: {labels}, Y-axis: {unit}. Chart colors match design system palette.` (절대 일반 카드로 대체하지 않음)
- **카메라 패키지** → `Camera viewfinder occupying top 70% of screen. Rectangular scan frame overlay in center. Capture button at bottom center.`
- **지도 패키지** → `Map area occupying {percentage}% of screen with markers. Search bar floating above map.`
- **리치 텍스트 패키지** → `Rich text editor with formatting toolbar at bottom: bold, italic, heading, list, quote buttons.`
- **결제 패키지** → `Subscription comparison cards: Free vs Premium. Feature checklist with check/lock icons. Primary CTA "프리미엄 시작".`
- **소셜 로그인** → `Social login button with {provider} logo and "{provider}로 시작하기" text.`

> **매핑 적용 순서:** PAGE STRUCTURE를 작성할 때 위에서 아래로 적용한다:
> 1. A6 → 화면 전체 레이아웃 구조 결정 (스크롤 유형, 고정 요소)
> 2. A3 → 네비게이션 요소 배치 (탭 바, Back 버튼, 하위 링크)
> 3. A2 → 기능 요소 배치 (버튼, 데이터, 인터랙션)
> 4. A4 → 데이터 필드 정밀 기술 (타입별 위젯, enum 옵션, nullable 처리)
> 5. A5 → 실제 한국어 텍스트 삽입 (빈 상태, 에러, 라벨)
> 6. A7 → 외부 패키지 렌더링 영역 기술 (차트, 카메라, 지도)

**Stitch 공식 프롬프팅 원칙:**
1. **Simple → Complex**: 간결하게 시작하고 edit으로 세분화
2. **Vibe로 분위기 설정**: 형용사가 색상, 폰트, 이미지에 영향
3. **한 번에 1-2가지만**: 여러 변경을 한 프롬프트에 넣지 않음
4. **UI/UX 키워드 활용**: navigation bar, card layout, floating action button 등
5. **5000자 이내**: 초과 시 컴포넌트 누락 위험

**프롬프트 구조 — 2-Block 패턴 (화면당 또는 배치당):**

> **⚠️ 핵심 교훈:** `"Continue using the X design system"` 텍스트 앵커만으로는 Stitch가 디자인 시스템을 인식하지 못한다. `./DESIGN.md`의 **실제 hex 코드, 폰트명, 스타일 규칙**을 프롬프트에 `DESIGN SYSTEM (REQUIRED)` 블록으로 직접 포함해야 한다. 이 블록이 없으면 Stitch가 자체 해석한 다른 색상/폰트를 생성한다.

```
{화면 유형} for {앱 이름} — {앱 설명 1줄}. {바이브 형용사 2-3개}.

**DESIGN SYSTEM (REQUIRED) — "{디자인 시스템 이름}":**
- Platform: Mobile (390×844), Phone-first
- Theme: {Light/Dark}, {스타일 설명}
- Background: {역할} ({이름}) (#hex)
- Surface Low: {역할} ({이름}) (#hex)
- Surface Elevated: {역할} ({이름}) (#hex)
- Primary Accent: {역할} ({이름}) (#hex) — {용도}
- Secondary: {역할} ({이름}) (#hex) — {용도}
- Tertiary: {역할} ({이름}) (#hex) — {용도}
- Text Primary: (#hex)
- Display/Headline Font: {폰트명} ({사이즈})
- Body/Label Font: {폰트명} ({사이즈})
- Borders: {규칙}
- Corners: {규칙}
- Elevation: {규칙}
- Spacing: {규칙}

**PAGE STRUCTURE:**
1. **{섹션}:** {설명}
2. **{섹션}:** {설명}
...

All UI text must be in Korean (한국어).
```

**DESIGN SYSTEM 블록 생성 규칙:**
1. `./DESIGN.md` 파일을 읽어서 모든 토큰을 추출한다
2. hex 코드, 폰트명, px 값을 정확히 포함한다 (이전의 "hex 금지" 규칙은 폐기)
3. 배치 생성 시 DESIGN SYSTEM 블록은 프롬프트 상단에 1번만 포함 (각 Screen 설명에는 미포함)
4. 5000자 이내를 준수하되, DESIGN SYSTEM 블록은 필수이므로 Screen 설명을 간결하게 조정

**프롬프트 예시 (도메인별):**

```
예시 A — 커머스 앱:
Product list screen for FreshCart — a grocery delivery app. Clean, modern, appetizing.

**DESIGN SYSTEM (REQUIRED) — "Fresh Market":**
- Platform: Mobile (390×844), Phone-first
- Theme: Light, clean, appetizing
- Background: White (#ffffff)
- Surface Low: Light Gray (#f8f9fa)
- Primary Accent: Fresh Green (#22c55e) — CTA, active states
- Secondary: Warm Orange (#f97316) — sale badges, prices
- Text Primary: Near Black (#18181b)
- Display Font: Plus Jakarta Sans (2rem)
- Body Font: Inter (1rem)
- Corners: Rounded (12px)
- Elevation: Soft shadows (8px blur, 8% opacity)

**PAGE STRUCTURE:**
1. Top bar with "상품" title and grid/list toggle
2. Category chips: 전체, 과일, 채소, 유제품, 음료
3. 2-column product grid with images, names, prices, add-to-cart buttons
4. Floating cart button with item count badge
5. Bottom navigation bar

All UI text must be in Korean (한국어).
```

```
예시 B — 피트니스 앱:
Dashboard screen for FitLog — a workout tracking app. Energetic, bold, motivating.

**DESIGN SYSTEM (REQUIRED) — "Active Pulse":**
- Platform: Mobile (390×844), Phone-first
- Theme: Dark, energetic, high-contrast
- Background: Deep Black (#0a0a0a)
- Surface Low: Dark Gray (#1c1c1e)
- Surface Elevated: Charcoal (#2c2c2e)
- Primary Accent: Electric Blue (#3b82f6) — CTA, progress rings
- Secondary: Neon Green (#22d3ee) — success, completed
- Tertiary: Coral (#f43f5e) — calories, heart rate
- Text Primary: White (#ffffff)
- Display Font: Satoshi (2.5rem bold)
- Body Font: Inter (1rem)
- Corners: Rounded (16px)
- Elevation: Glow shadows (primary color, 20% opacity)

**PAGE STRUCTURE:**
1. Top bar with greeting and streak counter
2. Today's summary card with calories, steps, active minutes
3. Recent workout list with type icons and duration
4. Circular progress ring for daily goal
5. Bottom navigation bar

All UI text must be in Korean (한국어).
```

**프롬프트 작성 규칙:**
- ✅ DESIGN SYSTEM (REQUIRED) 블록 필수 — `./DESIGN.md`에서 추출한 실제 토큰 포함
- ✅ hex 코드, 폰트명, px 값을 정확히 포함 (Stitch가 정확히 반영하려면 필수)
- ✅ 바이브 형용사로 분위기 설정 (warm, minimal, editorial, playful 등)
- ✅ UI/UX 키워드 사용 (navigation bar, card layout, hero section, floating action button)
- ✅ 요소를 구체적으로 참조 (primary button, search bar in header, image in hero section)
- ✅ 프롬프트는 영어, 마지막에: `All UI text must be in Korean (한국어).`
- ❌ 5000자 초과 프롬프트 금지 (컴포넌트 누락 위험)
- ❌ 한 프롬프트에 3개 이상 변경 사항 금지
- ❌ ~~hex 코드, px 값, 특정 폰트명 금지~~ → **폐기** (v3.4.2에서 변경)

**Output:** Feature별 프롬프트 (Feature당 15~20개). 모든 프롬프트에 DESIGN SYSTEM 블록 포함.

**Multi-State Screen 패턴 — 인터랙티브 UI 분해:**

Stitch는 정적 화면만 생성할 수 있으므로, **시간 경과 또는 사용자 인터랙션에 의해 UI가 크게 변하는 화면**은 각 상태를 별도 화면으로 분해하여 프롬프트를 작성한다.

| 인터랙티브 패턴 | 분해 방법 | 생성할 화면 |
|---------------|----------|-----------|
| **AI 채팅** | 대화 진행 단계별 | (1) 빈 대화 + 추천 질문, (2) 메시지 교환 중 (사용자 2 + AI 2 메시지 + 타이핑 인디케이터), (3) AI 스트리밍 응답 중 (부분 텍스트 + 로딩 인디케이터) |
| **카드 플립** (플래시카드) | 전면/후면 | (1) 카드 전면 (단어/질문, 큰 글자 중앙), (2) 카드 후면 (뜻/답변 + 예문 + 정답/오답 버튼) |
| **타이머/스톱워치** | 실행 상태별 | (1) 대기 상태 (00:00 + 시작 버튼), (2) 실행 중 (카운팅 숫자 + 일시정지 버튼), (3) 완료/축하 (결과 요약 + 통계) |
| **카메라/OCR 플로우** | 단계별 연속 화면 | (1) 카메라 뷰파인더 + 프레임 오버레이 + 캡처 버튼, (2) 결과 화면 (인식된 텍스트 하이라이트), (3) 텍스트 선택 (선택 가능한 블록), (4) 크롭/편집 (조정 핸들) |
| **오디오 플레이어** | 재생 상태별 | (1) 대기 (앨범아트/배경 + 재생 버튼), (2) 재생 중 (파형 시각화 + 진행 바 + 일시정지 버튼) |
| **음성 녹음** | 녹음 상태별 | (1) 대기 (녹음 버튼), (2) 녹음 중 (파형 + 시간 카운터 + 정지 버튼), (3) 녹음 완료 (재생 미리듣기 + 저장/삭제) |
| **드래그 리오더** | 편집 모드 | (1) 일반 리스트, (2) 편집 모드 (드래그 핸들 + 항목 하이라이트 + 상단 액션 바) |
| **성격 테스트/퀴즈** | 진행 단계별 | (1) 질문 화면 (진행률 바 + 질문 + 선택지), (2) 결과 화면 (결과 카드 + 추천 목록) |

**적용 방법:**
1. A8에서 위 패턴에 해당하는 화면을 식별한다 (A1 축4 grep + A2 Functional Scan + A7 패키지 감지)
2. 해당 화면의 상태 수만큼 A8 확장 테이블에 행을 추가한다 (축 태그: `Multi-State: {상태명}`)
3. A9 프롬프트에서 각 상태를 독립 화면으로 기술한다. 상태 간 연결을 PAGE STRUCTURE에 명시: `"This is state 2 of 3 in the chat flow. Previous: empty chat. Next: streaming response."`

### A10: Design Preview

**Goal:** 사용자의 디자인 취향을 파악하고, 레퍼런스 기반으로 디자인 방향을 제안한 뒤, 1화면 검증 → 3화면 확장 → 선택의 단계적 프로세스로 디자인을 확정한다. 모두 LIGHT 모드.

#### Phase 1: 사용자 취향 인터뷰 (필수)

시안 생성 전에 **반드시** 사용자의 디자인 선호를 파악한다. AskUserQuestion으로 진행:

```
질문 1: "디자인이 예쁘다고 느끼는 앱이나 웹사이트 2-3개를 알려주세요. (URL 또는 이름)"
   예: "replicate.com, Linear, 밀리의서재"

질문 2: "이런 디자인은 절대 싫다" 하는 스타일이 있나요?
   예: "원색이 강한 유치한 느낌", "둥글둥글한 장난감 같은 UI"

질문 3: 원하는 감성 키워드 2-3개를 골라주세요.
   선택지: 세련된 / 심플한 / 따뜻한 / 차분한 / 모던한 / 고급스러운 / 깔끔한 / 대담한
```

> **인터뷰 없이 시안을 생성하면 안 된다.** 사용자가 "빨리 진행" 요청 시에도 최소 질문 1(레퍼런스)은 받아야 한다.

#### Phase 2: 레퍼런스 심층 분석

사용자가 제공한 레퍼런스를 **실제로 분석**한다. 레퍼런스 유형(웹사이트 vs 모바일 앱)에 따라 분석 경로가 다르다.

**Step 1: 레퍼런스 유형 판별**

```
각 레퍼런스에 대해:
  → URL이 있고 브라우저로 접근 가능 → 웹사이트
  → 앱 이름 (Instagram, Threads, 밀리의서재 등) → 모바일 앱
  → 둘 다 있는 경우 → 모바일 앱 우선 (앱 UI가 본체, 웹 버전은 다름)
```

**Step 2-A: 웹사이트 분석 (WebFetch)**

```
WebFetch(url, "Analyze design system in detail:
  - Color palette (exact hex codes), background/surface/accent/text colors
  - Typography (font families, weights, size scale)
  - Spacing strategy (base unit, section gaps, card padding)
  - Shadows and borders (style, intensity, usage frequency)
  - Component styles (buttons, cards, navigation, inputs)
  - Color restraint level: how many colors does the UI itself use vs content?
  - What makes this design feel sophisticated/modern?")
```

**Step 2-B: 모바일 앱 분석 (Refero MCP)**

> **⚠️ 모바일 앱은 WebFetch로 웹 버전을 분석하면 안 된다.** 웹 버전과 앱 UI는 완전히 다르다.
> **Refero MCP**를 사용하여 실제 앱 스크린샷 기반으로 분석한다 (150K+ 스크린, 6K+ 플로우).

```
1. refero_search_screens로 앱의 핵심 화면 검색:

   mcp__refero__refero_search_screens({
     query: "{앱이름} home feed",
     platform: "ios"
   })
   
   mcp__refero__refero_search_screens({
     query: "{앱이름} profile",
     platform: "ios"
   })
   
   mcp__refero__refero_search_screens({
     query: "{앱이름} detail",
     platform: "ios"
   })

2. 반환된 description 필드에서 디자인 요소 추출:
   → Refero는 각 스크린샷의 시각적 설명을 상세히 제공:
     - 배경색 (hex 코드 포함)
     - 아이콘 스타일 (outlined/filled, stroke weight)
     - 타이포 (font family, weights, hierarchy)
     - 레이아웃 (grid, vertical stack, spacing)
     - 컴포넌트 (cards, buttons, navigation)
     - 전체 스타일 (minimalistic, content-focused 등)

3. 특정 화면 상세 분석이 필요하면:
   mcp__refero__refero_get_screen({ screen_id: "{id}" })

4. 사용자 플로우 분석이 필요하면:
   mcp__refero__refero_search_flows({
     query: "{앱이름} onboarding",
     platform: "ios"
   })
```

> **Refero MCP 미설치 시 Fallback:**
> 1. WebSearch "{앱이름} app UX UI design analysis color palette typography {year}"
> 2. WebSearch "{앱이름} UI kit figma community"
> → 디자인 분석 블로그/Figma 키트에서 간접 추출

> **자체 앱 분석**은 시뮬레이터에서 직접 실행:
> `xcrun simctl io booted screenshot /tmp/ref_self.png && sips -Z 1200 /tmp/ref_self.png`

**Step 3: 분석 결과 추출 (웹/앱 공통)**

```
각 레퍼런스에서 반드시 추출할 6가지:
| 요소 | 추출 내용 | 예시 |
|------|----------|------|
| 색상 전략 | 배경색, 악센트 사용 빈도, 채도 수준 | "순백 BG, 악센트 #0095F6 극소 사용" |
| 색상 절제도 | UI 무채색 vs 컬러풀 | "UI 무채색, 콘텐츠만 컬러" |
| 타이포 전략 | 서체, 위계 방식, 볼드 사용 | "SF Pro, 사이즈/웨이트로만 위계" |
| 공간 전략 | 여백량, 밀도, 카드 vs 플랫 | "4px 기본 단위, 넓은 여백" |
| 장식 수준 | 그림자/보더/아이콘 사용 빈도 | "그림자 미세, 보더 최소" |
| 모서리 전략 | border-radius 범위 | "4-8px, 과도한 둥근 모서리 없음" |
```

**Step 4: 분석 요약을 사용자에게 공유**

```
📊 레퍼런스 분석 결과:

1. replicate.com (웹사이트 — WebFetch 분석):
   → 순백 BG, UI 완전 무채색, 콘텐츠만 컬러
   → 타이포 위계만으로 구조, 그림자/보더 최소

2. Instagram (모바일 앱 — 시뮬레이터 스크린샷 분석):
   → [스크린샷 첨부] 순백 BG, 악센트 #0095F6 극소 사용 (좋아요/팔로우만)
   → SF Pro 시스템 폰트, 10+ 그레이 단계
   → 콘텐츠(사진)가 유일한 색상 소스, 바텀 탭 5개

3. Notion (모바일 앱 — 시뮬레이터 스크린샷 분석):
   → [스크린샷 첨부] 순백 BG, 극소 악센트
   → 넓은 여백, 타이포 위계, 플랫 카드

공통 DNA: "UI는 투명하고, 콘텐츠가 말한다"
```

#### Phase 3: 방향 정의 (레퍼런스 기반, 스펙트럼 아님)

> **⚠️ v4.3.0 변경:** 기존의 고정 7-스펙트럼 배분을 폐기한다. 대신 사용자 레퍼런스에서 파생된 **변형 3개**를 제안한다.

```
방향 정의 프로세스:
1. 레퍼런스 분석 결과를 "베이스 스타일"로 설정
2. 베이스에서 3가지 변형을 파생:
   - Direction A: 베이스 충실형 (레퍼런스 80% 반영)
   - Direction B: 베이스 + 앱 도메인 특화 (레퍼런스 60% + 도메인 색채 40%)
   - Direction C: 베이스 + 차별화 요소 (레퍼런스 50% + 독자적 아이덴티티 50%)
3. 사용자 확인 후 진행 (3개 중 택 1, 또는 수정 요청)
```

**변형 예시 (레퍼런스: replicate.com):**
```
Direction A "Monochrome Content-First":
  베이스 충실. 순백 BG, UI 무채색, 콘텐츠(책 표지)만 컬러.
  악센트: #374151 (gray-700). 진행바/활성탭도 near-black.

Direction B "Ink & Paper":
  베이스 + 독서 도메인 반영. 순백 BG, 아이보리 카드, 텍스트 위계 강조.
  악센트: #1E293B (slate-800). 크림색 서피스로 책 느낌 가미.

Direction C "Quiet Navy":
  베이스 구조 유지 + 브랜드 색상 1개 도입. 순백 BG, 네이비 악센트 최소 사용.
  악센트: #1E3A5F (navy) — 활성 탭과 FAB에만. 나머지 UI 전부 무채색.
```

**색상 절제 규칙 (Stitch AI 과색상 방지):**

Stitch AI가 색상 키워드를 받으면 모든 곳에 색상을 적용하는 경향이 있다. 이를 방지하기 위한 필수 규칙:

```
1. designMd에 "색상 사용 가능 위치"를 명시적으로 제한:
   - "Primary color is ONLY used for: active tab indicator, progress bar fill, FAB. 
     Everything else is grayscale (#111827, #6B7280, #9CA3AF, #D1D5DB)."
   
2. "DO NOT" 목록을 designMd에 포함:
   - "DO NOT use primary color for card backgrounds"
   - "DO NOT use primary color for section headers"
   - "DO NOT use colored badges or chips — use gray"
   - "DO NOT tint the page background — use pure white #FFFFFF"

3. 프롬프트에서도 색상 제한 반복:
   - "This design uses COLOR RESTRAINT. The UI is predominantly grayscale.
     Color comes from content (book covers, charts) not from UI elements."
```

#### Phase 4: 핵심 화면 선정 (3개 — 10개가 아님)

> **⚠️ v4.3.0 변경:** 기존 10개에서 **3개**로 축소. 빠른 검증 + 크레딧 절약.

```
선정 기준:
1. 앱의 "첫 인상" 화면 — 홈/대시보드 (레이아웃 다양성 검증)
2. 정보 밀도가 높은 화면 — 상세/통계 (타이포/색상 검증)
3. 인터랙션 화면 — 채팅/에디터/타이머 (컴포넌트 스타일 검증)

→ 사용자 확인 후 진행
```

#### Phase 5: 1화면 검증 (Gate)

> **⚠️ 핵심 변경: 대량 생성 전 반드시 1화면으로 방향 검증.**

```
1. Direction A의 핵심 화면 1개만 먼저 생성 (GEMINI_3_1_PRO)
2. 사용자에게 보여주고 피드백:
   - "이 방향이 맞나요?"
   - "색상이 너무 많다/적다?"
   - "전체적 느낌은 OK인데 X만 바꿔주세요"
3. Gate 통과 기준:
   - 사용자가 "OK" 또는 "이 방향으로" 확인
   - 수정 요청 시 → edit_screens로 조정 후 재확인
   - 방향 자체가 틀리면 → Phase 3으로 돌아가서 다른 Direction 제안
4. Gate 통과 후에만 나머지 2화면 생성 → 3개 확인 → 전체 확장
```

#### Phase 6: 3화면 확인 → 전체 확장

```
1. Gate 통과 후 나머지 2화면 생성
2. 3화면 모두 사용자 확인
3. 확인되면:
   - get_project → designTheme에서 DESIGN.md 추출
   - .prism/preview/{direction-name}/DESIGN.md 저장
   - ./DESIGN.md로 복사 (활성 시안)
   - .prism/preview/index.md 업데이트
4. A12로 진행
```

#### Phase 7 (선택): 추가 Direction 비교

사용자가 다른 방향도 보고 싶으면:
```
/prism preview add — Direction B 또는 C도 1화면 생성하여 비교
/prism preview add "Linear 느낌으로" — 텍스트 기반 새 방향
/prism preview add {이미지 URL} — 이미지 분석 기반 새 방향
```

**실행 요약:**
```
Phase 1: 인터뷰 (AskUserQuestion)
Phase 2: 레퍼런스 분석 (WebFetch/WebSearch)
Phase 3: 3개 Direction 정의 → 사용자 확인
Phase 4: 핵심 화면 3개 선정 → 사용자 확인
Phase 5: 1화면 검증 Gate (Direction A)
Phase 6: 3화면 확장 → DESIGN.md 확정
Phase 7: (선택) 추가 Direction 비교
```

**사용자 응답 처리:**
- "이 방향 좋아요" → Phase 6로 바로 진행
- "색상이 아직 많아요" → edit_screens로 조정 후 재검증
- "다른 방향도 보고 싶어요" → Phase 7 (추가 Direction)
- "전부 마음에 안 들어요" → Phase 1 인터뷰 재실행 (더 구체적 레퍼런스 요청)

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

### A11: Prompt Enhancement

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

```
Skill("enhance-prompt") 호출 1회
→ A9에서 작성한 원시 프롬프트를 전달
→ DESIGN.md 경로를 별도로 전달하지 않아도 됨
  (A10에서 선택한 시안이 ./DESIGN.md에 이미 존재하며,
   enhance-prompt 스킬이 자동으로 읽어서 디자인 토큰을 주입)
→ 결과를 .prism/prompts.md에 저장
```

### A12: Save Outputs

**Goal:** 분석 결과를 저장하고 사용자 확인을 받는다.

**파일 구조:**

```
./DESIGN.md                      ← 활성 시안의 DESIGN.md 복사본 (프로젝트 최상위)
.prism/
  analysis.md                    ← 공통 (A1-A9 산출물)
  prompts.md                     ← A11 결과
  preview/                       ← A10 시안 저장
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

## Navigation Flow Graph (A3)

### 탭 구조
| 탭 | 경로 | 화면 |
|----|------|------|
| 0 | / | HomeScreen |

### 라우트 트리
{A3에서 생성한 들여쓰기 라우트 트리 전체}

### 인증 가드
| 경로 | 가드 | 미인증 시 |
|------|------|----------|

## User Flows (Cross-Feature)

> A3 라우트 트리 + A2 네비게이션 분석에서 자동 추출.
> 화면 간 이동 경로를 문서화하여 design-pipeline D2의 Flow 매핑 입력으로 사용한다.

| # | Flow | Screens | Entry | Exit | 관련 Feature |
|---|------|---------|-------|------|-------------|
| F1 | {플로우명} | {화면ID 체인: 0-01→0-04→...→1-01} | {진입 조건} | {완료 화면} | F0, F1 |

### Flow 추출 규칙
1. **인증/온보딩**: 로그인 → 온보딩 → 메인 화면 진입까지의 전체 경로
2. **핵심 가치 루프**: 메인 콘텐츠 등록 → 상세 → 핵심 인터랙션 → 완료까지의 사이클
3. **등록 분기**: 콘텐츠 추가 시 검색/스캔/수동 등 분기 경로 각각
4. **멀티스텝 인터랙션**: Multi-State 태그가 3개 이상 연속인 화면 그룹 (타이머, 온보딩, 촬영 플로우 등)
5. **Cross-Feature 전환**: Feature 경계를 넘는 이동 (예: 상세→타이머→완료→통계)
6. **결제/업그레이드**: 페이월 → 구독 → 결제 → 복귀 라운드트립
7. **소셜 진입**: 커뮤니티 탐색 → 그룹 가입 → 활동 참여까지

---

## Data Model Map (A4)

> A4에서 추출한 핵심 엔티티, 필드, Enum, 관계. 프롬프트에서 데이터 필드를 정확한 타입으로 기술하고, design-pipeline에서 콘텐츠 치환 규칙(D3)의 입력으로 사용한다.

### 핵심 엔티티
| 엔티티 | 주요 필드 | 비고 |
|--------|----------|------|
| {Entity} | {field1: Type, field2: Type, ...} | {관계 등} |

### Enum 목록
| Enum | Values | UI 영향 |
|------|--------|---------|
| {EnumName} | {val1, val2, ...} | {칩/필터/배지 등} |

### 핵심 관계
| Parent | Child | Relation | UI Surface |
|--------|-------|----------|------------|
| {Parent} | {Child} | 1:N | {상세 → 목록} |

## Copy Inventory (A5)

> A5에서 추출한 앱 보이스 분석 + 핵심 UI 문구. 프롬프트에서 실제 앱 문구를 그대로 사용하고, 빈 상태/에러 메시지의 톤을 일관되게 유지한다.

### 앱 보이스
| 항목 | 값 |
|------|------|
| 톤 | {친근 존댓말 / 격식체 / ...} |
| 호칭 | {-어요 체 / -합니다 체} |
| 언어 | {한국어 / 영어 / ...} |

### 빈 상태 메시지
| 화면 | 메시지 |
|------|--------|
| {screen} | "{empty state message}" |

### 에러 메시지
| 상황 | 메시지 |
|------|--------|
| {situation} | "{error message}" |

## External Packages (A7)

> A7에서 감지한 UI에 영향을 주는 외부 패키지. 프롬프트에서 해당 패키지의 위젯/컴포넌트를 정확히 기술한다.

| 패키지 | 카테고리 | 영향받는 화면 | 프롬프트 영향 |
|--------|---------|-------------|-------------|
| {package_name} | {chart/camera/map/...} | {screen IDs} | {사용할 위젯/패턴} |

---

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
