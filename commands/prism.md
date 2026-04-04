---
name: prism
description: "Google Stitch AI design tool orchestrator — analyze, design, pipeline"
---

# /prism Command

Google Stitch AI design tool orchestration command.

## Usage

| Subcommand | Usage | Action |
|------------|-------|--------|
| `analyze` | `/prism analyze [app]` | 코드 분석 → Feature별 프롬프트 → .prism/analysis.md + prompts.md 산출 |
| `preview` | `/prism preview` | 핵심 화면 10개 × 7개 Direction 시안 생성 (LIGHT 모드) → 사용자 선택 → DESIGN.md |
| `design` | `/prism design <feature\|all>` | 디자인 생성 + 검증 루프 |
| `design resume` | `/prism design resume` | 크레딧 소진 등으로 중단된 design all 이어하기 |
| `pipeline` | `/prism pipeline [app]` | analyze → preview → design 전체 자동화 (원스텝) |
| `export` | `/prism export <feature\|all>` | Stitch 디자인 → Figma 내보내기 (미세 조정용) |
| `implement` | `/prism implement <feature\|all>` | Figma 디자인 → 프로젝트 코드 반영 |
| `recolor` | `/prism recolor [from <source>]` | DESIGN.md 색상만 변경 (시안 참조 / 파일 참조 / 직접 입력) |

## `/prism analyze [app]`

코드와 실행 화면을 분석하여 Feature별 UX-First 프롬프트를 산출한다.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/analyze-pipeline.md
   ```

2. **Phase A1-A12 실행**:
   - A1-A9: prism 자체 (코드 분석, Feature 분리, 원시 프롬프트)
   - A11: Skill("enhance-prompt") 호출 → 프롬프트 최적화
   - A12: `.prism/analysis.md` 작성 + `.prism/prompts.md` 작성

3. **사용자 확인 요청**

`app` 인자 예시: `/prism analyze readcodex`, `/prism analyze bookflip`
인자 없으면 현재 프로젝트 이름 사용.

## `/prism preview`

사용자 취향 인터뷰 → 레퍼런스 분석 → 1화면 검증 Gate → 3화면 확장으로 디자인을 확정한다 (LIGHT 모드).

### 실행 절차

1. `.prism/analysis.md` 존재 확인 (없으면 `/prism analyze` 먼저 실행 안내)
2. **사용자 취향 인터뷰** (필수): 좋아하는 앱/사이트 URL, 싫은 스타일, 감성 키워드
3. **레퍼런스 심층 분석**: 웹사이트=WebFetch, 모바일 앱=Refero MCP (실제 앱 스크린샷 분석)
4. **3개 Direction 정의** (레퍼런스 기반 변형): A 충실형 / B 도메인 특화 / C 차별화
5. **핵심 화면 3개 선정** (홈 + 상세 + 인터랙션) → 사용자 확인
6. **1화면 검증 Gate**: Direction A의 1화면만 먼저 생성 → 사용자 확인 필수
7. Gate 통과 → 나머지 2화면 확장 → DESIGN.md 확정 → `./DESIGN.md`로 복사

### 서브커맨드

| Usage | Action |
|-------|--------|
| `/prism preview` | 취향 인터뷰 → 레퍼런스 분석 → 3 Direction → 1화면 Gate → 확정 |
| `/prism preview add` | 새 시안 추가 (텍스트 / URL / 이미지 기반) |
| `/prism preview list` | 저장된 시안 목록 + 현재 활성 표시 |
| `/prism preview use <name>` | 저장된 시안을 `./DESIGN.md`로 활성화 |
| `/prism preview remove <name>` | 저장된 시안 삭제 |

## `/prism design <feature|all>`

코드를 분석하여 **모든 화면을 자동으로 발견**하고, Refero 레퍼런스를 매칭한 뒤, Stitch로 디자인을 생성하는 **완전 자동화 파이프라인**이다. 사전에 prompts.md가 필요 없다.

### 핵심 원칙 (MANDATORY)

1. **코드가 진실**: 라우터 + Screen 파일에서 모든 화면을 자동 발견한다. 수동 목록 금지.
2. **전수 생성**: 발견된 모든 화면(메인 상태, 빈 상태, 바텀시트, 모달 포함)을 생성. 건너뛰기 금지.
3. **Feature 완결 후 이동**: 한 Feature의 모든 화면이 확인될 때까지 다음으로 넘어가지 않는다.
4. **Refero → Stitch 연동**: 각 화면마다 Refero에서 레퍼런스를 검색하고, 그 레이아웃/구조 정보를 Stitch 프롬프트에 포함한다.

### Phase 1: 코드 기반 화면 발견 (자동)

1. **라우터 스캔**: `router.dart` 읽기 → 모든 `GoRoute`/`StatefulShellRoute` 경로 추출
2. **Screen 파일 스캔**: `Glob("**/features/**/presentation/**_screen.dart")` + `Glob("**/features/**/presentation/**_tab.dart")` → 모든 화면 위젯 발견
3. **각 화면 분석**: 발견된 각 Screen/Tab 파일을 읽어서 **모든 시각적 상태를 추출**:
   - 클래스명, 라우트 경로
   - `build()` 메서드의 UI 구조 (Scaffold, AppBar, body, FAB 등)
   - 사용되는 데이터 모델, Provider
   - **상태 변형 (각각 = 별도 Stitch surface)**:
     - `main` — 데이터가 있는 기본 populated 상태
     - `empty` — `isEmpty`, `empty`, `when(data: [])` 감지 시
     - `loading` — `shimmer`, `Shimmer`, `skeleton`, `CircularProgressIndicator` 감지 시
     - `tab:{name}` — `TabBar`/`TabBarView` 내 각 탭 (탭 수만큼 surface)
     - `viewMode:{mode}` — `ViewMode`, `_isGrid`, `_isCompact`, `_isCover`, `GridView`/`ListView` 토글 감지 시
     - `edit` — `_isEditing`, `_isSelecting`, `editMode` 감지 시
     - `search:{state}` — 검색 화면의 empty/typing/results/noResults
   - **오버레이 (각각 = 별도 Stitch surface)**:
     - `sheet:{name}` — `showModalBottomSheet`, 별도 *_sheet.dart 파일
     - `dialog:{name}` — `showDialog`, `AlertDialog`
   - **위젯 파일 스캔**: `widgets/` 디렉토리의 *_sheet.dart, *_dialog.dart, *_bottom_sheet.dart도 포함
4. **화면 인벤토리 생성**: `.prism/screen-inventory.md` 에 기록:
   ```markdown
   | # | Feature | Screen | Surface | Type | Description |
   |---|---------|--------|---------|------|-------------|
   | 1 | auth | LoginScreen | main | screen | 소셜 로그인 |
   | 2 | books | ReadingTab | main | screen | 읽는 중 리스트 (3권) |
   | 3 | books | ReadingTab | empty | state | 빈 상태 |
   | 4 | books | ReadingTab | viewMode:cover | variant | 커버 뷰 모드 |
   | 5 | books | ReadingTab | viewMode:compact | variant | 컴팩트 리스트 모드 |
   | 6 | books | BookshelfTab | main | screen | 3열 그리드 |
   | 7 | books | BookshelfTab | viewMode:list | variant | 리스트 뷰 모드 |
   | 8 | books | BookshelfTab | edit | variant | 편집/선택 모드 |
   | 9 | books | BookDetailScreen | main | screen | 책 상세 |
   | 10 | books | BookDetailScreen | sheet:statusChange | sheet | 상태 변경 시트 |
   | 11 | books | BookDetailScreen | sheet:tagSelect | sheet | 태그 선택 시트 |
   | 12 | books | BookDetailScreen | dialog:delete | dialog | 삭제 확인 |
   ```
   **목표: 250+ surfaces** (메인 + 빈 상태 + 로딩 + 탭 변형 + 뷰 모드 + 바텀시트 + 다이얼로그 + 편집 모드)
5. **Feature별 그룹핑** + 총 화면 수 계산
6. **사용자 확인**:
   ```
   코드에서 {N}개 화면 발견: {Feature별 카운트}
   Stitch 화면 생성 수: {총 surfaces} (메인 + 빈 상태 + 바텀시트 + 다이얼로그)
   진행할까요?
   ```

### Stitch 스킬 연동 (MANDATORY)

`/prism design`은 아래 스킬을 **반드시** 호출하여 사용한다. 직접 프롬프트를 수동 작성하지 않는다.

| Phase | 호출 스킬 | 용도 |
|-------|----------|------|
| Phase 2 (Refero) | — | Refero MCP 직접 호출 |
| Phase 3 준비 | `Skill("design-md")` | DESIGN.md → Stitch 디자인 시스템 합성 |
| Phase 3 프롬프트 | `Skill("enhance-prompt")` | 각 화면 프롬프트를 UI/UX 키워드로 강화 |
| Phase 3 생성 | `Skill("stitch-design")` | text-to-design 워크플로우로 화면 생성/편집 |
| 반복 생성 | `Skill("stitch-loop")` | baton 패턴으로 자율 순차 생성 (대량 화면 시) |

**프롬프트 생성 절차** (각 surface마다):
1. 코드에서 UI 구조 추출 → 원시 프롬프트 생성
2. `Skill("enhance-prompt")` 호출 → UI/UX 키워드 주입, 분위기/구조 강화
3. Refero description 결합 (있는 경우)
4. `Skill("stitch-design")` 의 text-to-design 워크플로우로 Stitch에 전송

**대량 생성 시** (Feature 화면 10개 이상):
- `Skill("stitch-loop")` 의 baton 패턴 사용
- `.stitch/next-prompt.md`에 다음 화면 정보를 기록하며 자율 순차 생성

### Phase 2: Refero 레퍼런스 자동 매핑

**Screen 단위로** Refero 검색 (surface 단위가 아님 — 같은 Screen의 변형은 같은 레퍼런스 공유):
1. **screen-inventory.md에서 고유 Screen 목록 추출** (Surface가 아닌 Screen 기준 = ~77개)
2. 화면 유형 → 검색 키워드 자동 생성 (아래 키워드 맵 참조)
3. `refero_search_screens(query, platform="ios")` 호출
4. 상위 2개 결과의 `app_name` + `description` (레이아웃/구조 부분만) → `.prism/refero-cache.md`에 캐싱:
   ```markdown
   ## BookDetailScreen
   - Ref1: PocketShelf — book detail editing with cover, fields, dropdown
   - Ref2: Oku — book card list with ratings and covers
   ```
5. **병렬 처리**: Agent 서브에이전트로 10개씩 병렬 검색 또는 순차 5개씩 전송
6. 매핑률 보고 후 **자동 진행** (사용자 확인 불필요)

### Phase 3: Stitch 디자인 생성 (Feature별 순차)

#### 준비
1. `.prism/project-ids.md` 확인/생성
   - Feature별 Stitch 프로젝트가 없으면: `create_project` → `create_design_system` (DESIGN.md 기반)
   - `create_design_system` 파라미터는 DESIGN.md의 Stitch Config 섹션에서 추출
2. 각 프로젝트에 DS 적용 확인 (`list_design_systems`)

#### 프롬프트 생성 규칙 (Surface 유형별)

**Screen (main)**: 코드 구조 + Refero + 샘플 데이터
```
{Screen명} — {Feature명} (메인 상태)

레이아웃 (코드 기반):
- AppBar: {코드에서 추출한 title, leading, actions}
- Body: {build() 메서드의 위젯 트리를 자연어로 변환}
- {FAB/BottomNav/TabBar 등 있으면 포함}

데이터 (한국어 샘플):
- {Provider/모델에서 추출한 필드 + 현실적인 한국어 샘플값}

참고 레이아웃 (Refero):
- {refero-cache.md의 해당 Screen description}

한국어 UI
```

**Empty State**: 빈 상태 전용
```
{Screen명} — 빈 상태

코드의 빈 상태 위젯:
- {코드에서 추출한 empty 메시지, 아이콘, CTA 버튼}
- 일러스트: 라인 아트 (#1A1A1A stroke)
- 나머지 구조(AppBar, BottomNav)는 메인과 동일

한국어 UI
```

**Loading State**: 로딩/스켈레톤
```
{Screen명} — 로딩 상태

Shimmer 스켈레톤 화면:
- AppBar/BottomNav는 메인과 동일
- Body 영역: {코드의 리스트/그리드 구조에 맞는 shimmer placeholder}
- 색상: #F5F5F5 → #E5E7EB 반짝임 효과

한국어 UI
```

**Tab Variant**: 탭 변형
```
{Screen명} — "{탭이름}" 탭 활성

{메인 프롬프트와 동일한 쉘} + 해당 탭의 콘텐츠:
- 탭바: "{탭이름}" 활성 (#1A1A1A bold 밑줄), 나머지 비활성 (#9CA3AF)
- 콘텐츠: {해당 탭의 build 내용}

한국어 UI
```

**ViewMode Variant**: 뷰 모드 변형
```
{Screen명} — {모드명} 뷰 모드

{메인과 동일한 데이터} + 뷰 모드 변경:
- {grid: 3열 커버 그리드 / list: 세로 리스트 행 / cover: PageView 큰 커버}
- 뷰 모드 토글 아이콘 상태 변경

한국어 UI
```

**BottomSheet**: 바텀시트 오픈 상태
```
{Screen명} — {시트명} 바텀시트

배경: {메인 화면이 어둡게 dim 처리}
바텀시트 (#FFFFFF bg, 상단 12px radius, 핸들):
- {코드에서 추출한 시트 내용: 옵션 리스트/폼/선택기}

한국어 UI
```

**Dialog**: 다이얼로그 오버레이
```
{Screen명} — {다이얼로그명}

배경: {메인 화면 dim}
중앙 다이얼로그 (#FFFFFF bg, 12px radius):
- {코드에서 추출한 제목, 메시지, 버튼}

한국어 UI
```

#### 전송 규칙
1. **2개씩 병렬 전송**: `generate_screen_from_text(projectId, prompt, modelId="GEMINI_3_1_PRO", deviceType="MOBILE")`
2. **타임아웃 처리**: 바로 다음 2개 전송. Feature 전체 전송 완료 후 30초 대기 → `list_screens` 일괄 확인.
3. **누락 재시도**: 미생성 화면 1회 재시도.
4. **Feature 완결 후 이동**: 모든 surface가 확인될 때까지 다음 Feature로 넘어가지 않는다.
5. **Feature 완료 보고**:
   ```
   F{N} {name}: {생성}/{목표} surfaces
   URL: https://stitch.withgoogle.com/projects/{projectId}
   ```
6. **상태 파일 업데이트** (화면 단위)

### Phase 4: 검증

1. 모든 Feature 완료 후 `screen-inventory.md` 대비 Stitch 화면 수 비교
2. **커버리지 100% 확인**: 누락 있으면 추가 생성
3. 최종 보고:
   ```
   전체 완료: {생성}/{목표} surfaces ({비율}%)
   Feature별 URL + surface 수
   목표 250+ 달성 여부
   ```

### 상태 파일 (`.claude/prism-pipelines/{시안}.local.md`)

```yaml
---
phase: scanning | refero-mapping | generating | verifying | complete
total_screens: 0
total_surfaces: 0
generated: 0
current_feature: 0
completed_features:
failed_screens:
---
```

### `/prism design resume`

1. 상태 파일에서 `phase`, `current_feature` 확인
2. `list_screens`로 이미 생성된 화면 확인
3. 미생성 화면부터 재개 (Phase 2 또는 3)

### 화면 유형별 Refero 키워드 맵

| 화면 유형 | Refero 검색 키워드 |
|-----------|-------------------|
| Login/Auth | social login Google Apple sign in minimal |
| Onboarding | onboarding welcome goal preference |
| Library/List | book library bookshelf grid list covers |
| Detail | book detail reading progress metadata |
| Form/Register | form input registration edit fields |
| Search | search results list filter |
| Timer | timer stopwatch session tracker |
| Notes/Editor | note editor rich text memo |
| Quotes | quotes highlight bookmark reading |
| Statistics | statistics dashboard charts analytics |
| Vocabulary | vocabulary flashcard word learning |
| AI Chat | AI chat conversation assistant |
| Recommendations | recommendation suggestion curated |
| Club/Group | book club community group discussion |
| Social Feed | social feed timeline activity posts |
| Profile | user profile account settings |
| Settings | settings preferences account management |
| Camera/Scanner | barcode scanner camera OCR |
| Subscription | subscription billing plan pricing |
| Empty State | empty state illustration placeholder |
| BottomSheet | bottom sheet modal options |

`feature` 인자: `/prism design library`, `/prism design all`
인자 없으면 Feature 목록 표시 후 선택.

### 크레딧 소진 시 이어하기

```bash
# 크레딧 소진으로 중단됨 (시안: Warm Organic, Feature 3에서 멈춤)

# 방법 1: 계정 전환 후 이어하기
/prism account neworld         # 다른 계정으로 전환 → 세션 재시작
/prism design resume            # Feature 3부터 이어서 생성

# 방법 2: 다른 시안으로 전환 작업
/prism preview use editorial-elegance   # 시안 전환 (Warm Organic 상태 자동 백업)
/prism design all                        # Editorial Elegance로 새로 시작

# 방법 3: 다시 Warm Organic으로 돌아와서 이어하기
/prism preview use warm-organic          # 시안 전환 (상태 자동 복원)
/prism design resume                     # Feature 3부터 이어서 생성
```

시안별 진행 상황은 `.claude/prism-pipelines/{시안이름}.local.md`에 독립 보존된다.

## `/prism pipeline [app]`

analyze → preview → design을 원스텝으로 자동 실행한다.

### 실행 절차

1. `/prism analyze [app]` 실행
2. 분석 요약 표시 후 자동 진행 (간략 요약만 출력, 명시적 거부 없으면 진행)
3. `/prism preview` 실행
4. `/prism design all` 실행
5. 전체 Feature 순차 처리

## `/prism export <feature|all>`

Stitch 네이티브 "Figma 내보내기"를 CDP로 자동화하여 디자인을 Figma로 완벽 이전한다.

### 사전 요구사항

- Chrome 디버그 모드: `open -a "Google Chrome" --args --remote-debugging-port=9222`
- chrome-viewer 서버 실행 (포트 6080)
- Stitch에 로그인된 상태 (Chrome 브라우저)

### 실행 절차

1. `.prism/project-ids.md`에서 Stitch 프로젝트 ID 확인
2. CDP로 Chrome iframe 탭에 연결
3. Stitch 프로젝트 열기 → "내보내기" 클릭 → ⌘+A 모두 선택
4. "Figma" 옵션 선택 → "변환" 클릭
5. `.prism/figma-ids.md`에 Figma 파일 URL 기록
6. 안내: "Figma에서 미세 조정 후 `/prism implement <feature>` 실행"

### 사용 예시

```bash
/prism export library          # Library Feature만 Figma로
/prism export all              # 모든 Feature를 순차 Figma로
```

## `/prism implement <feature|all>`

Figma에서 미세 조정된 디자인을 프로젝트 코드에 반영한다.

### 실행 절차

1. `.prism/figma-ids.md`에서 Figma 파일 key 확인 (없으면 export 먼저 안내)
2. `get_design_context`로 Figma에서 코드 참조 + 스크린샷 추출
3. 프로젝트 스택에 맞게 코드 변환 (Flutter/React/Next.js)
4. 빌드/테스트 → 오류 수정
5. 시뮬레이터/브라우저 스크린샷 → Figma 디자인과 비교 검증

### 사용 예시

```bash
# 기본 흐름: design → export → Figma 수정 → implement
/prism design all              # Stitch 디자인 생성
/prism export all              # Figma로 내보내기
# → 사용자가 Figma에서 미세 조정
/prism implement all           # 코드에 반영
```

## `/prism recolor`

DESIGN.md의 색상 팔레트만 변경한다. 폰트, roundness, designMd 규칙 등은 유지. 3가지 입력 방식을 지원한다.

### 사용법

| 방식 | 사용법 | 설명 |
|------|--------|------|
| 시안 참조 | `/prism recolor from <시안이름>` | 저장된 시안의 색상을 가져옴 |
| 파일 참조 | `/prism recolor from <DESIGN.md 경로>` | 지정한 DESIGN.md에서 색상 추출 |
| 직접 입력 | `/prism recolor` | hex 코드 직접 입력 |

**예시:**
```bash
# 저장된 시안에서 색상 가져오기
/prism recolor from japanese-zen
/prism recolor from earthy-natural

# 특정 DESIGN.md 파일에서 색상 참조
/prism recolor from .prism/preview/playful-pastel/DESIGN.md

# 인자 없이 실행 → hex 직접 입력
/prism recolor
```

### 실행 절차

1. **현재 DESIGN.md 읽기**: `./DESIGN.md` 존재 필수. 없으면 안내.

2. **색상 소스 결정** (인자에 따라 분기):

   **`from <시안이름>` — 저장된 시안에서 가져오기:**
   ```
   1. .prism/preview/<시안이름>/DESIGN.md 읽기
   2. 해당 파일에서 4개 seed 색상 추출:
      - overridePrimaryColor, overrideSecondaryColor
      - overrideTertiaryColor, overrideNeutralColor
   3. 추출된 색상을 사용자에게 표시 후 확인
   ```

   **`from <파일경로>` — 지정 파일에서 가져오기:**
   ```
   1. 지정된 DESIGN.md 파일 읽기
   2. Design Identity 테이블 또는 Named Colors에서 4색 추출
   3. 테이블에 없으면 overrideXxxColor 패턴으로 grep
   4. 추출된 색상을 사용자에게 표시 후 확인
   ```

   **인자 없음 — 직접 입력:**
   ```
   1. 현재 4색 표시
   2. AskUserQuestion으로 새 색상 입력 받기
      - 4개 중 바꾸고 싶은 것만 입력 (나머지 유지)
      - hex 코드 또는 색상 이름 (AI가 hex 변환)
   ```

3. **변경 전후 색상 비교 표시**:
   ```
   색상 변경 미리보기:
                   현재                    →  새 색상
   Primary:   #041627 (Navy)           →  #2D4B37 (Forest Green)
   Secondary: #775a19 (Gold)           →  #C36A4B (Terracotta)
   Tertiary:  #e9c176 (Gold Light)     →  #D9B99B (Sand)
   Neutral:   #fbf9f5 (Cream)          →  #F4F1EA (Linen)

   적용하시겠습니까?
   ```

4. **Stitch 프로젝트 디자인 시스템 업데이트**:
   - `.prism/project-ids.md`에서 모든 Feature 프로젝트 ID 로드
   - 각 프로젝트에 대해:
     a. `list_design_systems(projectId)` → asset ID 확인
     b. `update_design_system` 호출:
        - `overridePrimaryColor`, `overrideSecondaryColor`, `overrideTertiaryColor`, `overrideNeutralColor` 변경
        - `displayName`, `headlineFont`, `bodyFont`, `labelFont`, `roundness`, `colorMode`, `colorVariant` 유지
        - `designMd` 유지 (색상 참조는 5단계에서 치환)
     c. `get_project` → 새로운 `designTheme.namedColors` + `designMd` 가져오기
     d. `apply_design_system(projectId, screenInstances, assetId)` → 모든 화면에 일괄 적용

5. **DESIGN.md 업데이트**:
   - Design Identity 테이블의 색상 값 업데이트
   - Named Colors 토큰 맵을 Stitch가 생성한 새 토큰으로 교체
   - Design System Spec을 Stitch가 생성한 새 designMd로 교체
     (Stitch가 새 색상에 맞게 designMd 내 hex 참조를 자동 재생성)

6. **.prism/preview/{현재 활성 시안}/DESIGN.md도 동기화**

7. **결과 확인**: 변경된 색상 + 영향받은 프로젝트 수 + Stitch 링크

### 색상만 변경, 나머지 유지

**변경되는 것:**
- 4개 seed 색상 (`overridePrimaryColor`, `overrideSecondaryColor`, `overrideTertiaryColor`, `overrideNeutralColor`)
- `namedColors` 전체 (~55개 토큰, Stitch가 새 seed에서 자동 재생성)
- `designMd` 내 색상 참조 (Stitch가 새 designMd를 자동 생성)

**유지되는 것:**
- `displayName` (디자인 시스템 이름)
- `headlineFont`, `bodyFont`, `labelFont` (서체)
- `roundness` (모서리)
- `colorMode` (Light/Dark)
- `colorVariant` (Fidelity 등)
- `spacingScale`
- 디자인 규칙의 구조 (No-Line Rule, Ghost Border, Ink Mist 등 — Stitch가 새 색상에 맞게 재작성)

### 주의사항

- recolor 후 기존 화면에 `apply_design_system`으로 새 색상이 일괄 적용됨
- 크레딧 소비: `update_design_system`은 무료, `apply_design_system`은 화면당 크레딧 소비 가능
- 아직 생성되지 않은 Feature의 화면에는 영향 없음 (다음 `design` 실행 시 새 DESIGN.md 참조)
- `from` 참조 시 원본 시안의 DESIGN.md는 변경되지 않음 (색상만 복사)

## Stitch API Rules (MANDATORY)

### Model — GEMINI_3_1_PRO ONLY
**모든 Stitch 화면 생성/편집 호출에 반드시 `modelId: "GEMINI_3_1_PRO"`를 사용한다.**
- `generate_screen_from_text` → `modelId: "GEMINI_3_1_PRO"`
- `edit_screens` → `modelId: "GEMINI_3_1_PRO"`
- `generate_variants` → `modelId: "GEMINI_3_1_PRO"`
- **GEMINI_3_FLASH 사용 금지** — 타임아웃이 발생해도 모델을 변경하지 않는다.
- 타임아웃 시: 재시도하지 말고, 30초 대기 후 `list_screens`로 백그라운드 생성 완료 여부를 확인한다.

### Design System — 중복 생성 방지
1. **화면 생성 전** 반드시 `create_design_system`으로 프로젝트에 디자인 시스템을 먼저 적용한다.
2. 화면 생성 후 Stitch가 새 디자인 시스템을 만들었다면, `apply_design_system`으로 올바른 asset을 덮어씌운다.
3. 프로젝트당 디자인 시스템 asset ID는 `.prism/project-ids.md`에 기록한다.

### Timeout Handling
- Stitch `generate_screen_from_text`는 수 분이 걸릴 수 있다.
- 타임아웃 = 실패가 아니다. 백그라운드에서 생성이 계속된다.
- 타임아웃 후 절차: `sleep 30` → `list_screens(projectId)` → 화면 존재 확인
- 확인 후에도 없으면 1회만 재시도 (동일 modelId: GEMINI_3_1_PRO)

## Execution

1. Activate the `prism` skill
2. Execute the requested subcommand following the skill's workflow references

## No Arguments

If called without arguments (`/prism`), show the usage table above and ask what the user wants to do.

## Error Handling

- **공식 스킬 미설치**: 자동 설치 시도 → 실패 시 안내
- **인증 실패**: STITCH_API_KEY → gcloud ADC → 안내
- **Rate limit**: 파이프라인 시작 시 크레딧 안내
- **analysis.md 미존재**: `/prism analyze` 먼저 실행 안내
- **타임아웃**: 모델 변경 금지. 30초 대기 후 list_screens 확인 (위 Stitch API Rules 참조)
