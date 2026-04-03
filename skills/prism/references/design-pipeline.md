# Design Pipeline — `/prism design <feature|all>`

> **v4.4.0:** Stitch AI 생성 대신 **Refero MCP의 실제 앱 스크린샷을 직접 참조**하여 구현한다.
> 검증된 실제 앱 디자인을 그대로 가져오므로 AI 해석에 의한 품질 저하가 없다.

Analyze 파이프라인은 `references/analyze-pipeline.md` 참조.

---

## 전체 흐름

```
D1: analysis.md 로드 → 화면 목록 확보
D2: Refero 매핑 → 각 화면에 레퍼런스 스크린 매칭
D3: 매핑 검토 → 사용자 확인
D4: 구현 → Refero description 기반 Flutter 코드 작성
D5: 검증 → 레퍼런스와 구현 비교
D6: 완료
```

---

### Feature Routing (all 모드 전용)

1. Read `.claude/prism-design-pipeline.local.md` → `feature` 필드 확인
2. `.prism/analysis.md`에서 해당 Feature 화면 목록 추출

### D1: 화면 목록 로드

**Goal:** analysis.md에서 구현할 화면 목록을 확보한다.

**Steps:**
1. `.prism/analysis.md` 존재 확인 (없으면 `/prism analyze` 먼저 실행 안내)
2. 해당 Feature의 화면 테이블 로드 (화면 ID, 이름, 축 태그, 코드 파일)
3. Preview에서 선택한 레퍼런스 앱 목록 확인 (`.prism/preview/index.md`)

### D2: Refero 매핑 — 화면별 레퍼런스 매칭

**Goal:** analysis.md의 각 화면에 대해 Refero에서 **가장 적합한 레퍼런스 스크린**을 찾아 매핑한다.

**매핑 전략:**

```
각 화면의 축 태그(Axis Tag)에 따라 검색 쿼리를 구성:

| 축 태그 | Refero 검색 쿼리 예시 |
|---------|---------------------|
| Primary (홈/리스트) | "{레퍼런스앱} home feed" / "{레퍼런스앱} list" |
| Primary (상세) | "{레퍼런스앱} detail page" / "book detail card" |
| Primary (에디터) | "text editor" / "note editor" / "rich text" |
| Primary (타이머) | "timer countdown" / "meditation timer" |
| Primary (통계) | "analytics dashboard" / "stats chart" |
| Primary (채팅) | "chat conversation AI" / "messaging" |
| Primary (프로필) | "{레퍼런스앱} profile settings" |
| Data:empty | "empty state illustration" / "no content" |
| Data:skeleton | "skeleton loading placeholder" |
| Data:error | "error state retry" |
| Overlay:bottom-sheet | "bottom sheet options" / "action sheet" |
| Overlay:dialog | "confirmation dialog modal" |
| Interaction:edit-mode | "edit mode selection" / "multi-select" |
| Interaction:search | "search results filter" |
| Multi-State (플래시카드) | "flashcard quiz" / "learning card flip" |
| Auth:free-tier | "paywall subscription" / "premium upgrade" |
```

**실행:**

```
1. 각 화면에 대해 refero_search_screens 호출:

   mcp__refero__refero_search_screens({
     query: "{검색 쿼리}",
     platform: "ios"
   })

2. 반환된 결과에서 최적 매칭 선정:
   - 같은 앱(레퍼런스 앱)의 스크린 우선
   - page_types, ux_patterns, ui_elements가 원본 화면과 유사한 것 선택
   - description을 읽어서 레이아웃/구성요소가 맞는지 확인

3. 매칭 결과를 .prism/refero-mapping.md에 기록

4. Multi-Step 플로우 화면은 refero_search_flows로 매칭:

   mcp__refero__refero_search_flows({
     query: "{플로우 검색 쿼리}",
     platform: "ios"
   })

   | 플로우 유형 | Refero 검색 쿼리 예시 |
   |-----------|---------------------|
   | 온보딩 | "onboarding welcome" / "{앱} signing up" |
   | 로그인 | "sign in" / "{앱} logging in" |
   | OCR/카메라 | "camera capture scan" / "photo upload crop" |
   | 완독/완료 | "completion celebration" / "goal achieved" |
   | 타이머 세션 | "timer session start pause complete" |
   | 구독/결제 | "subscription upgrade paywall" / "checkout" |
   | 검색 플로우 | "search filter results" |

   → flow_id로 상세 확인:
   mcp__refero__refero_get_flow({ flow_id: {id} })
   → 각 step의 화면 description + 화면 간 전환 로직 확보
   → 플로우 전체를 하나의 매핑 단위로 기록
```

**매핑 파일 형식 (.prism/refero-mapping.md):**

```markdown
# ReadCodex · Refero Mapping

## 레퍼런스 앱
- Primary: Instagram (color restraint, content-first)
- Secondary: Notion (typography hierarchy, whitespace)
- Accent: Threads (feed layout, social patterns)

## Feature 1: Library (v2)

| # | ReadCodex 화면 | Refero Screen ID | Refero 앱 | 화면 유형 | URL |
|---|---------------|-------------------|----------|----------|-----|
| 1-01 | LibraryScreen (탭 셸) | {screen_id} | Instagram | Home Feed | https://refero.design/s/{id} |
| 1-02 | ReadingTab 커버모드 | {screen_id} | Instagram | Home Feed | ... |
| 1-04 | ReadingTab empty | {screen_id} | Notion | Empty State | ... |
| 1-05 | ReadingTab skeleton | {screen_id} | Instagram | Loading | ... |
...

## Flow 매핑

| # | ReadCodex 플로우 | Refero Flow ID | Refero 앱 | Steps | URL |
|---|-----------------|----------------|----------|-------|-----|
| F-01 | 온보딩 (Welcome→Goal→Genre→Complete) | {flow_id} | {앱} | 4 | https://refero.design/f/{id} |
| F-02 | 로그인 (Splash→Form→Loading→Home) | {flow_id} | Instagram | 6 | ... |
| F-03 | OCR (촬영→선택→결과) | {flow_id} | {앱} | 3 | ... |
| F-04 | 완독 (평점→감상→축하) | {flow_id} | {앱} | 3 | ... |
...
```

> **매핑 비율 목표:** 80% 이상의 화면이 Refero 매핑을 가져야 한다.
> 매칭이 어려운 화면(앱 특화 기능)은 `매핑 없음 — 자체 디자인` 표시.

### D3: 매핑 검토

**Goal:** 매핑 결과를 사용자에게 보여주고 확인받는다.

**Steps:**
1. Feature별 매핑 요약 표시:
   ```
   Feature 1: Library (v2) — 27개 중 22개 매핑 (81%)
     Primary: 6/6 매핑
     Data States: 4/5 매핑 (partial 1개 자체)
     Overlays: 5/7 매핑
     ...
   ```
2. 매핑률이 80% 미만이면 추가 검색 제안
3. 사용자 확인: "이 매핑으로 진행할까요?"
4. 수정 요청 시: 특정 화면의 레퍼런스 변경

### D4: 구현 — Refero Description 기반

**Goal:** Refero의 화면 description을 구현 스펙으로 사용하여 Flutter 코드를 작성한다.

> **⚠️ 핵심 원칙: Refero description의 레이아웃/구조/스타일을 최대한 그대로 옮긴다.**
> 변경하는 것은 **콘텐츠만** (Instagram 사진 → 책 표지, 스토리 → 읽는 중 책 등).

**구현 절차 (화면당):**

```
1. refero_get_screen으로 상세 정보 로드:
   mcp__refero__refero_get_screen({ screen_id: "{id}" })

2. description에서 구현 스펙 추출:
   - 배경색 (#FFFFFF 등)
   - 레이아웃 구조 (vertical stack, grid, horizontal scroll 등)
   - 컴포넌트 목록 (avatar, card, button, icon, tab bar 등)
   - 타이포 (font weight, size hierarchy)
   - 간격/패딩 (generous, compact 등)
   - 아이콘 스타일 (outlined, filled, stroke weight)
   - 특수 효과 (gradient, shadow, blur 등)

3. 콘텐츠 치환 매핑:
   | Refero (원본) | ReadCodex (치환) |
   |-------------|-----------------|
   | 사진/이미지 포스트 | 책 표지 이미지 |
   | 스토리 아바타 행 | 읽고 있는 책 PageView |
   | 좋아요/댓글/공유 | 진행률/메모/인용구 |
   | 유저 프로필 | 책 저자/출판사 |
   | 피드 목록 | 서재 책 목록 |
   | 검색 그리드 | 책 검색 그리드 |

4. Flutter 위젯으로 구현:
   - description의 레이아웃 → Column, Row, ListView, GridView 등
   - description의 색상 → theme.colorScheme 토큰
   - description의 타이포 → theme.textTheme 토큰
   - description의 간격 → SizedBox, Padding 값
   
5. DESIGN.md의 디자인 시스템 토큰을 적용:
   - Refero description의 hex 코드가 아닌 프로젝트 DESIGN.md의 토큰 사용
   - 구조/레이아웃은 Refero, 색상/폰트는 DESIGN.md
```

**구현 단위:**
- 화면별 순차 구현 (Primary → States → Overlays → Interactions)
- 각 화면 구현 후 `refero-design` 스킬의 검증 규칙 적용

### D5: 검증

**Goal:** 구현된 Flutter 화면이 Refero 레퍼런스의 느낌을 충실히 재현했는지 확인한다.

**검증 체크리스트:**

```
구조 일치:
- [ ] 레이아웃 구조가 레퍼런스와 동일한가 (vertical stack, grid 등)
- [ ] 컴포넌트 배치 순서가 동일한가
- [ ] 네비게이션 패턴이 동일한가 (탭 바, 헤더)

스타일 일치:
- [ ] 색상 절제도가 레퍼런스와 유사한가 (무채색 UI + 콘텐츠 컬러)
- [ ] 타이포 위계가 동일한가 (크기/굵기 차이)
- [ ] 아이콘 스타일이 일관적인가 (outlined vs filled)
- [ ] 여백/간격 수준이 유사한가

콘텐츠 적합:
- [ ] 독서 앱 콘텐츠로 적절히 치환되었는가
- [ ] 한국어 텍스트가 올바른가
- [ ] 빈 상태/에러 메시지가 앱 보이스와 일치하는가
```

**검증 방법:**
1. 시뮬레이터에서 구현된 화면 스크린샷 촬영
2. Refero 레퍼런스 URL과 나란히 비교
3. 체크리스트 항목별 pass/fail
4. gaps > 0 이면 D4로 돌아가서 수정

### D6: 완료

1. Feature 매핑 + 구현 완료 확인
2. 상태 파일 업데이트 (completed_features에 추가)
3. 다음 Feature로 진행 또는 전체 완료

---

## Feature 루프

`/prism design all`일 때:

```
Feature 0 → D1(화면 로드) → D2(Refero 매핑) → D3(검토) → D4(구현) → D5(검증) → D6
Feature 1 → D1 → D2 → D3 → D4 → D5 → D6
...
Feature 10 → D1 → D2 → D3 → D4 → D5 → D6 → 전체 완료
```

**핵심:** 모든 Feature가 동일한 레퍼런스 앱 세트를 기반으로 일관된 디자인을 유지한다.

---

## Stitch 모드 (선택적)

Refero 매핑 대신 기존 Stitch 생성 모드를 사용하려면:

```
/prism design all --stitch
```

이 경우 기존 v4.3.x의 Stitch 파이프라인(prompts.md → create_project → generate_screen_from_text)이 실행된다.
기본값은 Refero 모드.

---

## `/prism design resume`

```
1. .claude/prism-design-pipeline.local.md 존재 확인
2. 상태 파일에서 진행 상황 읽기:
   - mode: refero (또는 stitch)
   - current_feature, completed_features
   - mapping_status: 매핑 완료 여부
3. 중단 지점부터 재개:
   - 매핑 중 중단 → D2 이어서
   - 구현 중 중단 → D4 이어서
4. 진행 상황 표시 후 계속
```
